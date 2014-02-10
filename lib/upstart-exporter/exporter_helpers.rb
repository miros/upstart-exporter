class Upstart::Exporter
  module ExporterHelpers
    def export_cmd_helper(cmd_name, cmd, binds={})
      helper_script_cont = Templates.helper binds.merge(:cmd => cmd)
      File.open(helper_cmd_conf(cmd_name), 'w') do |f|
        f.write(helper_script_cont)
      end
    end

    def app_name
      @options[:prefix] + @options[:app_name]
    end

    def app_cmd(cmd_name)
      "#{app_name}-#{cmd_name}"
    end

    def upstart_cmd_conf(cmd_name)
      File.join(@options[:upstart_dir], "#{app_cmd(cmd_name)}.conf")
    end

    def helper_cmd_conf(cmd_name)
      File.join(@options[:helper_dir], "#{app_cmd(cmd_name)}.sh")
    end
  end
end
