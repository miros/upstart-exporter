require "yaml"
require "upstart-exporter/version"
require "upstart-exporter/templates"
require "upstart-exporter/errors"
require "upstart-exporter/options/global"
require "upstart-exporter/options/command_line"

module Upstart
  class Exporter
    include Errors

    attr_reader :options
  
    def initialize(command_line_args)
      global_options = Options::Global.new
      command_line_options = Options::CommandLine.new(command_line_args)
      @options = global_options.merge(command_line_options)
      ensure_dirs
    end

    def export
      clear
      export_app
      options[:commands].each do |cmd_name, cmd|
        export_command(cmd_name, cmd)
      end
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

    protected

    def ensure_dirs
      ensure_dir(options[:helper_dir])
      ensure_dir(options[:upstart_dir])
    end

    def app_name
      options[:prefix] + options[:app_name]
    end

    def export_app
      app_conf = Templates.app :app_name => app_name, :run_user => options[:run_user], :run_group => options[:run_group]
      File.open(upstart_conf, 'w') do |f|
        f.write(app_conf)
      end
    end

    def ensure_dir(dir)
      FileUtils.mkdir_p(dir) unless FileTest.directory?(dir)
      error "Path #{dir} does not exist" unless FileTest.directory?(dir)
    end

    def upstart_conf
      File.join(options[:upstart_dir], "#{app_name}.conf")
    end

    def app_cmd(cmd_name)
      "#{app_name}-#{cmd_name}"
    end
    
    def upstart_cmd_conf(cmd_name)
      File.join(options[:upstart_dir], "#{app_cmd(cmd_name)}.conf")
    end
    
    def helper_cmd_conf(cmd_name)
      File.join(options[:helper_dir], "#{app_cmd(cmd_name)}.sh")
    end

    def export_cmd_helper(cmd_name, cmd)
      helper_script_cont = Templates.helper :cmd => cmd
      File.open(helper_cmd_conf(cmd_name), 'w') do |f|
        f.write(helper_script_cont)
      end
    end

    def export_cmd_upstart_conf(cmd_name)
      cmd_upstart_conf_content = Templates.command :app_name => app_name, :run_user => options[:run_user], :run_group => options[:run_group], :cmd_name => cmd_name, :helper_cmd_conf => helper_cmd_conf(cmd_name)
      File.open(upstart_cmd_conf(cmd_name), 'w') do |f|
        f.write(cmd_upstart_conf_content)
      end
    end

    def export_command(cmd_name, cmd)
      export_cmd_helper(cmd_name, cmd)
      export_cmd_upstart_conf(cmd_name)
    end

  end
end
