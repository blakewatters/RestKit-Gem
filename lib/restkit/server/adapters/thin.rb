module RestKit
  module Server
    module Adapters
      class Thin
        attr_reader :config
        attr_accessor :config_file, :thin_bin
        
        def initialize(config)
          @config = config
          @config_file = 'Tests/Server/thin.yml'
          @thin_bin = 'bundle exec thin'
        end
        
        def run_command
          %Q(#{thin_bin} #{rackup_switch} -p #{config.port} start)          
        end
        
        def start_command
          %Q(#{thin_bin} #{rackup_switch}#{config_file_switch}start)          
        end
        
        def stop_command
          %Q(#{thin_bin} #{rackup_switch}#{config_file_switch}stop)          
        end
        
        def restart_command
          %Q(#{thin_bin} #{rackup_switch}#{config_file_switch}restart)
        end
        
        def define_tasks(server_task)
          config_file_argument = config_file_switch
          server_task.instance_eval do
            namespace :thin do
              desc 'Generate a Thin configuration for executing the server'
              task :generate do
                command = "#{thin_bin} -P #{config.port} -R #{config.rackup_file} -d -l #{config.log_file} -P #{config.pid_file} #{config_file_argument} config"
                RestKit::Shell.execute(command)
              end
            end
          end
        end
        
        private
          def config_file_switch
            config_file ? "-C #{config_file} " : nil
          end
          
          def rackup_switch
            config.rackup_file ? "-R #{config.rackup_file} " : nil
          end
      end
    end
  end
end
