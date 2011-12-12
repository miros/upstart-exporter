require "upstart-exporter/version"

module Upstart
  class ExportError < RuntimeError; end

  class Exporter
    DEFAULTS = {
      'helper_dir' => '/var/local/upstart_helpers/',
      'upstart_dir' => '/etc/init/',
      'run_user' => 'service'
    }
    CONF = '/etc/upstart-exporter.yaml'

    attr_accessor :helper_dir, :upstart_dir, :run_user

    def initialize(options)
      process_opts(options)
      read_global_opts
      check_dir(@helper_dir)
      check_dir(@upstart_dir)
    end


    def read_global_opts
      config = if FileTest.file?(CONF)
        YAML::load(File.read(CONF))
      else
        STDERR.puts "#{CONF} not found"
        {}
      end
      %w{helper_dir upstart_dir run_user}.each do |param|
        value = if config[param]
          config[param]
        else
          STDERR.puts "Param #{param} is not set, taking default value #{DEFAULTS[param]}"
          DEFAULTS[param]
        end
        self.send "#{param}=", value
      end
    end

    def process_opts(options)
      @commands = if options[:clear]
        {}
      else
        process_procfile(options[:procfile])
      end
      process_appname(options[:app_name])
    end

    def process_procfile(name)
      error "#{name} is not a readable file" unless FileTest.file?(name)
      commands = {}
      content = File.read(name)
      content.lines.each do |line|
        line.chomp!
        if line =~ /^(\w+?):(.*)$/
          label = $1
          command = $2
          commands[label] = command
        else
          error "procfile lines should have the following format: 'some_label: command'"
        end
      end
      commands
    end

    def process_appname(app_name)
      error "Application name should contain only letters (and underscore) and be nonempty, so #{app_name.inspect} is not suitable" unless app_name =~ /^\w+$/ 
      @app_name = "fb-#{app_name}"
    end

    def check_dir(dir)
      FileUtils.mkdir_p(dir) unless FileTest.directory?(dir)
      error "Path #{dir} does not exist" unless FileTest.directory?(dir)
    end

    def export
      clear
      export_app
      @commands.each do |cmd_name, cmd|
        export_command(cmd_name, cmd)
      end
    end

    HELPER_TPL = <<-HEREDOC
#!/bin/sh
%s
HEREDOC

    APP_TPL = <<-HEREDOC
pre-start script

bash << "EOF"
  mkdir -p /var/log/fb-%s
  chown -R %s /var/log/fb-%s
EOF

end script
HEREDOC

    COMMAND_TPL = <<-HEREDOC
start on starting %s
stop on stopping %s
HEREDOC


    COMMAND_REAL_TPL = <<-HEREDOC
start on starting %s
stop on stopping %s
respawn

exec sudo -u %s /bin/sh %s >> /var/log/fb-%s/%s.log 2>&1
HEREDOC

    def upstart_conf
      File.join(@upstart_dir, "#{@app_name}.conf")
    end

    def app_cmd(cmd_name)
      "#{@app_name}-#{cmd_name}"
    end
    
    def upstart_cmd_conf(cmd_name)
      File.join(@upstart_dir, "#{app_cmd(cmd_name)}.conf")
    end
    
    def helper_cmd_conf(cmd_name)
      File.join(@helper_dir, "#{app_cmd(cmd_name)}.sh")
    end

    def clear
      FileUtils.rm(upstart_conf) if FileTest.file?(upstart_conf)
      Dir[upstart_cmd_conf('*')].each do |f|
        FileUtils.rm(f)
      end
      Dir[helper_cmd_conf('*')].each do |f|
        FileUtils.rm(f)
      end
    end

    def export_app
      app_conf = APP_TPL % [@app_name, @run_user, @app_name]
      File.open(upstart_conf, 'w') do |f|
        f.write(app_conf)
      end
    end

    def export_cmd_helper(cmd_name, cmd)
      helper_script_cont = HELPER_TPL % [cmd]
      File.open(helper_cmd_conf(cmd_name), 'w') do |f|
        f.write(helper_script_cont)
      end
    end

    def export_cmd_upstart_confs(cmd_name)
      cmd_upstart_conf_content = COMMAND_TPL % [@app_name, @app_name]
      File.open(upstart_cmd_conf(cmd_name), 'w') do |f|
        f.write(cmd_upstart_conf_content)
      end
      
      cmd_upstart_conf_content_real = COMMAND_REAL_TPL % [app_cmd(cmd_name), app_cmd(cmd_name), @run_user, helper_cmd_conf(cmd_name), @app_name, cmd_name]
      File.open(upstart_cmd_conf(cmd_name + '-real'), 'w') do |f|
        f.write(cmd_upstart_conf_content_real)
      end
    end

    def export_command(cmd_name, cmd)
      export_cmd_helper(cmd_name, cmd)
      export_cmd_upstart_confs(cmd_name)
    end

    def error(msg)
      raise Upstart::ExportError, msg 
    end
  end
end
