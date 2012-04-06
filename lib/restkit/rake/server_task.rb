require 'restkit/server'
require 'restkit/server/adapters'

module RestKit
  module Rake
    class ServerTask < ::Rake::TaskLib
      include ::Rake::DSL if defined?(::Rake::DSL)
    
      attr_accessor :name    
      attr_accessor :host
      attr_accessor :port
      attr_accessor :pid_file
      attr_accessor :rackup_file
      attr_accessor :log_file
      attr_accessor :echo_commands
    
      def initialize(name = :server)
        @name = name
        @host = '127.0.0.1'
        @port = 4567
        @pid_file = 'Tests/Server/server.pid'
        @log_file = 'Tests/Server/server.log'
        @rackup_file = 'Tests/Server/server.ru'
        @echo_commands = true
        yield self if block_given?
        define_tasks
      end
    
      def adapter(name = :return_value)
        return @adapter if name == :return_value
      
        if name == :thin
          @adapter = RestKit::Server::Adapters::Thin.new(self)
        elsif name == :custom
          @adapter = RestKit::Server::Adapters::Custom.new(self)
        else
          raise ArgumentError, "Unknown adapter #{name.inspect}"
        end
      
        yield @adapter if block_given?
      end
    
      def method_missing(method, *args, &block)
        if adapter.respond_to?(method)
          adapter.send(method, *args, &block)
        else
          super
        end
      end
    
      private
        def define_tasks
          RestKit::Shell.echo_commands = @echo_commands
        
          # Allow the adapter to define tasks
          adapter.define_tasks(self) if adapter.respond_to?(:define_tasks)
        
          namespace name do
            task :run do
              if File.exists?(pid_file)
                pid = File.read(pid_file).chomp
                server_status = ServerStatus.new(pid, host, port)
                server_status.check
                if server_status.up?
                  puts "Unable to run server: Existing process with pid #{server_status.pid} found listening on #{server_status.host}:#{server_status.port}"
                  exit(1)
                end
              end

              RestKit::Shell.execute(run_command)
            end

            desc "Start the Test server daemon"
            task :start do
              RestKit::Shell.execute(start_command).exit
            end

            desc "Stop the Test server daemon"
            task :stop do
              RestKit::Shell.execute(stop_command).exit
            end

            desc "Restart the Test server daemon"
            task :restart do
              RestKit::Shell.execute(restart_command).exit
            end

            desc "Check the status of the Test server daemon"
            task :status do
              if File.exists?(pid_file)
                pid = File.read(pid_file).chomp
              else
                pid = nil
              end

              server_status = RestKit::Server::Status.new(pid, host, port)
              server_status.check
              if server_status.listening?
                puts server_status.to_s
              else
                puts "No server found listening on #{server_status.host_and_port}"
              end
            end
            
            desc "Abort the task chain unless the Test server is running"
            task :abort_unless_running do
              server_status = RestKit::Server::Status.new(nil, host, port)
              server_status.check
              unless server_status.listening?
                exit(-1)
              end
            end
          
            namespace :logs do
              desc "Tails the Test server logs"
              task :tail do
                command = %Q{tail -f #{log_file}}
                RestKit::Shell.execute(command)
              end
            end

            desc "Dumps the last 25 lines from the Test server logs"
            task :logs do
              command = %Q{tail -n 25 #{log_file}}
              RestKit::Shell.execute(command)
            end
          end

          desc 'Run the Test server in the foreground'
          task name => ["#{name}:run"]        
        end
    end
  end
end
