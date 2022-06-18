require 'rails_helper'

module Genova
  module Ecs
    describe Client do
      before do
        service_client_mock = double(Ecs::Deployer::Service::Client)
        allow(service_client_mock).to receive(:wait_timeout=)
        allow(service_client_mock).to receive(:update)
        allow(service_client_mock).to receive(:exist?).and_return(true)
        allow(Ecs::Deployer::Service::Client).to receive(:new).and_return(service_client_mock)

        task_definition_mock = double(Aws::ECS::Types::TaskDefinition)
        allow(task_definition_mock).to receive(:task_definition_arn).and_return('task_definition_arn')

        task_client_mock = double(Ecs::Task::Client)
        allow(task_client_mock).to receive(:register).and_return(task_definition_mock)

        ecr_client_mock = double(Ecr::Client)
        allow(ecr_client_mock).to receive(:push_image)
        allow(ecr_client_mock).to receive(:destroy_images)
        allow(Ecr::Client).to receive(:new).and_return(ecr_client_mock)

        allow(Ecs::Task::Client).to receive(:new).and_return(task_client_mock)

        docker_client_mock = double(Genova::Docker::Client)
        allow(docker_client_mock).to receive(:build_image).and_return(['repository_name'])
        allow(Genova::Docker::Client).to receive(:new).and_return(docker_client_mock)
      end

      describe 'deploy_service' do
        let(:code_manager_mock) { double(CodeManager::Git) }
        let(:client) { Ecs::Client.new('cluster', code_manager_mock) }
        let(:deploy_config_mock) { double(Genova::Config::TaskDefinitionConfig) }

        it 'should be return DeployResponse' do
          allow(deploy_config_mock).to receive(:find_service).and_return(
            containers: [
              name: 'web'
            ],
          )
          allow(deploy_config_mock).to receive(:find_cluster).and_return([])
          allow(code_manager_mock).to receive(:load_deploy_config).and_return(deploy_config_mock)
          allow(code_manager_mock).to receive(:task_definition_config_path).and_return('task_definition_path')

          task_client_mock = double(Ecs::Task::Client)
          allow(task_client_mock).to receive(:register).and_return(
            container_definitions: [
              {
                name: 'web'
              }
            ]
          )
          allow(task_client_mock).to receive(:task_definition_arn)
          allow(Ecs::Task::Client).to receive(:new).and_return(task_client_mock)

          expect(client.deploy_service('service', 'tag_revision')).to be_a(DeployResponse)
        end
      end
    end
  end
end
