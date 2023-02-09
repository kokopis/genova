module Genova
  module Deploy
    class Runner
      class << self
        def call(deploy_job, options = {})
          @logger = Genova::Logger::MongodbLogger.new(deploy_job)
          @logger.level = options[:verbose] ? :debug : Settings.logger.level
          @logger.info('Start deployment.')

          @deploy_job = deploy_job
          @options = options

          transaction = Genova::Deploy::Transaction.new(@deploy_job.repository, logger: @logger, force: @options[:force])

          begin
            transaction.begin
            start
            transaction.commit
          rescue Interrupt
            @logger.info('Deploy detected forced termination.')

            transaction.cancel
            @deploy_job.update_status_cancel

            exit 1
          rescue => e
            @logger.error('Deployment failed.')
            @logger.error(e.message)
            @logger.error(e.backtrace.join("\n"))

            transaction.cancel
            @deploy_job.update_status_failure

            exit 1
          end
        end

        def start
          ecs = Ecs::Client.new(@deploy_job, logger: @logger)

          @deploy_job.status = DeployJob.status.find_value(:in_progress).to_s
          @deploy_job.started_at = Time.now.utc
          @deploy_job.commit_id = ecs.ready
          @deploy_job.save

          case @deploy_job.type
          when DeployJob.type.find_value(:run_task)
            ecs.deploy_run_task
          when DeployJob.type.find_value(:service)
            ecs.deploy_service(async_wait: @options[:async_wait])
          when DeployJob.type.find_value(:scheduled_task)
            ecs.deploy_scheduled_task
          end
        end

        def finished(deploy_job, logger)
          return unless Settings.github.deployment_tag && deploy_job.branch.present?

          logger.info("Push tags to Git. [#{deploy_job.label}]")

          deploy_job.deployment_tag = deploy_job.label
          code_manager = CodeManager::Git.new(
            deploy_job.repository,
            branch: deploy_job.branch,
            tag: deploy_job.tag,
            alias: deploy_job.alias,
            logger: logger
          )
          code_manager.release(deploy_job.deployment_tag, deploy_job.commit_id)

          @logger.info('Deployment is complete.')
        end
      end
    end
  end
end
