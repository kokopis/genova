require 'rails_helper'

module Github
  describe RetrieveBranchWorker do
    describe 'perform' do
      let(:bot) { double(Genova::Slack::Interactive::Bot) }

      include_context :session_start

      before do
        Redis.current.flushdb

        allow(bot).to receive(:ask_branch)
        allow(Genova::Slack::Interactive::Bot).to receive(:new).and_return(bot)

        Genova::Slack::SessionStore.start!(id, 'user')
        subject.perform(id)
      end

      it 'should be in queue' do
        is_expected.to be_processed_in(:github_retrieve_branch)
      end

      it 'should be no retry' do
        is_expected.to be_retryable(false)
      end
    end
  end
end
