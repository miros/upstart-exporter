module Upstart
  class Exporter
    class Templates

      def self.helper(binds)
        interpolate(HELPER_TPL, binds)
      end

      def self.app(binds)
        interpolate(APP_TPL, binds)
      end

      def self.command(binds)
        interpolate(COMMAND_TPL, binds)
      end

      protected

      HELPER_TPL = <<-HEREDOC
#!/bin/sh
{{cmd}}
HEREDOC

      APP_TPL = <<-HEREDOC
pre-start script

bash << "EOF"
  mkdir -p /var/log/{{app_name}}
  chown -R {{run_user}} /var/log/{{app_name}}
EOF

end script
HEREDOC

      COMMAND_TPL = <<-HEREDOC
start on starting {{app_name}}
stop on stopping {{app_name}}
respawn

script
  touch /var/log/{{app_name}}/{{cmd_name}}.log
  chown {{run_user}} /var/log/{{app_name}}/{{cmd_name}}.log
  exec sudo -u {{run_user}} /bin/sh {{helper_cmd_conf}} >> /var/log/{{app_name}}/{{cmd_name}}.log 2>&1
end
HEREDOC

      def self.interpolate(str, substitutes)
        str_copy = str.dup
        substitutes.each do |k, v|
          str_copy.gsub!("{{#{k}}}", v)
        end
        str_copy
      end

    end
  end
end
    