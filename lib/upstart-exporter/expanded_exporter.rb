class Upstart::Exporter
  class ExpandedExporter
    include ExporterHelpers
    include Errors

    def self.export(options)
      new(options).export
    end

    def initialize(options)
      @config = options[:commands]
      @options = options
      @commands = @config['commands']
      @env = @config['env'] || {}
      @dir = @config['working_directory'] || ''
    end

    def export
      @commands.each do |command, value|
        if count = value['count']
          count.times do |counter|
            export_cmd("#{command}_#{counter}", value)
          end
        else
          export_cmd(command, value)
        end
      end
    end

  private

    def export_cmd(command, value)
      script = value['command']
      script = add_env_command(script, value)
      script = add_dir_command(script, value)
      export_cmd_helper(command, script)
      export_cmd_upstart_conf(command, value)
    end

    def add_env_command(script, command)
      vars = ''
      env = @env.merge((command['env'] || {}))
      env.each do |var, val|
        vars += "#{var}=#{val} "
      end
      if vars.empty?
        script
      else
        "env #{vars} #{script}"
      end
    end

    def add_dir_command(script, command)
      dir = command['working_directory'] || @dir
      if dir.empty?
        script
      else
        "cd '#{dir}' && #{script}"
      end
    end

    def respawn(cmd_options)
      respawn_enabled = if cmd_options['respawn'] != nil
        cmd_options['respawn']
      elsif @config['respawn'] != nil
        @config['respawn']
      else
        true
      end
      respawn_enabled ? 'respawn' : ''
    end

    def respawn_limit(cmd_options)
      lim = cmd_options['respawn_limit'] || @config['respawn_limit']
      return '' unless lim
      "respawn limit #{lim['count']} #{lim['interval']}"
    end

    def start_on
      "#{@config['start_on_runlevel']}"
    end

    def stop_on
      "#{@config['stop_on_runlevel']}"
    end

    def export_cmd_upstart_conf(cmd_name, cmd_options)
      cmd_upstart_conf_content = Templates.command(
        :app_name => app_name,
        :start_on => start_on,
        :stop_on => stop_on,
        :run_user => @options[:run_user],
        :run_group => @options[:run_group],
        :cmd_name => cmd_name,
        :helper_cmd_conf => helper_cmd_conf(cmd_name),
        :respawn => respawn(cmd_options),
        :respawn_limit => respawn_limit(cmd_options)
      )
      File.open(upstart_cmd_conf(cmd_name), 'w') do |f|
        f.write(cmd_upstart_conf_content)
      end
    end
  end
end
