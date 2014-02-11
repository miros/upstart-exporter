class Upstart::Exporter
  module ExporterHelpers
    def export_cmd_helper(cmd_name, cmd, binds={})
      helper_script_cont = Templates.helper helper_binds(cmd, binds)
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

    private

    def helper_binds(cmd, binds)
      return binds unless cmd

      *start, tail = cmd.split /\s*(&&|\|\|)\s*/
      tail.gsub!(/\A(exec\s*|\s*)/, "exec ")
      exec_cmd = start.push(tail).join(" ")

      binds.merge(:cmd => cmd, :exec_cmd => exec_cmd)
    end
  end
end
