module Upstart::Exporter::Options
  class Validator

    include Upstart::Exporter::Errors

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def call
      clean_params = {
        :app_name => reject_special_symbols(options[:app_name]),
        :helper_dir => validate_path(options[:helper_dir]),
        :upstart_dir => validate_path(options[:upstart_dir]),
        :run_user => reject_special_symbols(options[:run_user]),
        :run_group => reject_special_symbols(options[:run_group]),
        :prefix => reject_special_symbols(options[:prefix]),
        :start_on_runlevel => validate_runlevel(options[:start_on_runlevel]),
        :stop_on_runlevel => validate_runlevel(options[:stop_on_runlevel]),
        :kill_timeout => validate_digits(options[:kill_timeout]),
        :respawn => validate_respawn(options[:respawn]),
        :working_directory => validate_path(options[:working_directory]),
        :procfile_commands => validate_procfile(options[:procfile_commands])
      }

      clean_params
    end

    private

      def validate_procfile(config)
        if config[:version] == 2
          validate_procfile_v2(config)
        else
          config
        end
      end

      def validate_procfile_v2(config)
        clean_params = validate_command_params(config)
        clean_params[:version] = config[:version]

        if config[:commands]
          clean_params[:commands] = Hash[config[:commands].map {|name, cmd| [name, validate_command_params(cmd)]}]
        end

        clean_params
      end

      def validate_command_params(cmd)
        {
          :command => cmd[:command],
          :start_on_runlevel => validate_runlevel(cmd[:start_on_runlevel]),
          :stop_on_runlevel => validate_runlevel(cmd[:stop_on_runlevel]),
          :working_directory => validate_path(cmd[:working_directory]),
          :respawn => validate_respawn(cmd[:respawn]),
          :count => validate_digits(cmd[:count]),
          :kill_timeout => validate_digits(cmd[:kill_timeout]),
          :env => validate_env(cmd[:env]),
          :log => validate_path(cmd[:log])
        }
      end

      def validate_env(params)
        return unless params
        params.each_key {|k| reject_special_symbols(k)}
        params
      end

      def validate_respawn(options)
        return options unless options.is_a?(Hash)

        {
          :count => validate_digits(options[:count]),
          :interval => validate_digits(options[:interval])
        }
      end

      def validate_path(val)
        validate(val, /\A[A-Za-z0-9_\-.\/]+\z/)
      end

      def reject_special_symbols(val)
        validate(val, /\A[A-Za-z0-9_\-]+\z/)
      end

      def validate_runlevel(val)
        validate(val, /\A\[\d+\]\z/)
      end

      def validate_digits(val)
        validate(val, /\A\d+\z/)
      end

      def validate(val, regexp)
        str_val = val.to_s
        return if str_val == ""

        unless str_val =~ regexp
          error("value #{val} is insecure and can't be accepted")
        end

        val
      end

  end
end