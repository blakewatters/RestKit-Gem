module RestKit
  module Server
    module Adapters
      class Custom
        attr_reader :config
        attr_accessor :start_command, :stop_command, :restart_command, :run_command
        
        def initialize(config)
          @config = config
        end
      end
    end
  end
end
