module Genova
  module Slack
    module Command
      class Version
        def self.call(_statements, _user, _parent_message_ts)
          client = Genova::Slack::Interactive::Bot.new
          client.send_message(Genova::Version::LONG_STRING)
        end
      end
    end
  end
end
