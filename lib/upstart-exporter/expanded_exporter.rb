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
      @log = @config['log'] || ''
      @kill_timeout = @config['kill_timeout'] || options[:kill_timeout]
    end

    def export
      @commands.each do |command, cmd_options|
        if count = cmd_options['count']
          count.times do |counter|
            export_cmd("#{command}_#{counter}", cmd_options)
          end
        else
          export_cmd(command, cmd_options)
        end
      end
    end

  private

    def export_cmd(command, cmd_options)
      cmd_options = { 'working_directory' => @dir,
                      'log' => @log,
                      'kill_timeout' => @kill_timeout }.merge(cmd_options)

      script = cmd_options['command']
      script = add_env_command(script, cmd_options)
      script = add_dir_command(script, cmd_options)
      script = add_log_command(script, cmd_options)

      export_cmd_helper(command, script, cmd_options)
      export_cmd_upstart_conf(command, cmd_options)
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
      dir = command['working_directory']
      if dir.empty?
        script
      else
        "cd '#{dir}' && #{script}"
      end
    end

    def add_log_command(script, command)
      log = command['log']
      if log.empty?
        script
      else
        "#{script} >> #{log} 2>&1"
      end
    end

    def respawn_options(cmd_options)
      if cmd_options.has_key?('respawn')
        cmd_options['respawn']
      elsif @config.has_key?('respawn')
        @config['respawn']
      else
        {}
      end
    end

    def respawn(cmd_options)
      respawn_options(cmd_options) ? 'respawn' : ''
    end

    def respawn_limit(cmd_options)
      limits = respawn_options(cmd_options)
      return '' unless limits && limits['count'] && limits['interval']
      "respawn limit #{limits['count'].to_i} #{limits['interval'].to_i}"
    end

    def start_on
      "starting #{app_name}"
    end

    def stop_on
      "stopping #{app_name}"
    end

    def kill_timeout(cmd_options)
      cmd_options.fetch('kill_timeout', @kill_timeout)
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
        :respawn_limit => respawn_limit(cmd_options),
        :kill_timeout => kill_timeout(cmd_options)
      )
      File.open(upstart_cmd_conf(cmd_name), 'w') do |f|
        f.write(cmd_upstart_conf_content)
      end
    end
  end
end
