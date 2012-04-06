class Process::Status
  def exit
    Kernel.exit(self.exitstatus)
  end
end

module RestKit
  module Shell    
    class << self
      # When true, commands will be echoed before execution
      def echo_commands=(on_off)
        @echo_commands = on_off
      end
      
      def echo_commands?
        @echo_commands
      end
      
      def execute(command)
        puts "Executing: `#{command}`" if configatron.server.commands.echo
        system(command)
        return $?
      end
    end
  end
end
