class Upstart::Exporter
  module ExporterHelpers
    def export_cmd_helper(cmd_name, cmd, binds={})
      helper_script_cont = Templates.helper append_cmd(cmd, binds)
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

    def append_cmd(cmd, binds)
      return binds unless cmd

      parts = cmd.split /\s*(&&|\|\|)\s*/
      parts.push ensure_prepend_exec(parts.pop)

      binds.merge(:cmd => parts.join(" "))
    end

    def ensure_prepend_exec(cmd)
      cmd = guard_leading_env_var(cmd.strip)
      cmd.gsub(/\A(exec\s*|\s*)/, "exec ")
    end

    def guard_leading_env_var(cmd)
      if cmd =~ /\A\S+=\S+/
        warn "WARNING: Command '#{cmd}' seems to start with assignment of environment var. Prepending with 'env'"
        "env #{cmd}"
      else
        cmd
      end
    end
  end
end
