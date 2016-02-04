module Upstart::Exporter::Options
  class Validator

    include Upstart::Exporter::Errors

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def validate!
      validate_path(options[:helper_dir])
      validate_path(options[:upstart_dir])

      reject_special_symbols(options[:run_user])
      reject_special_symbols(options[:run_group])
      reject_special_symbols(options[:prefix])

      validate_runlevel(options[:start_on_runlevel])
      validate_runlevel(options[:stop_on_runlevel])

      validate_digits(options[:kill_timeout])

      validate_respawn(options[:respawn])

      if options[:procfile_commands][:version] == 2
        validate_procfile_v2(options[:procfile_commands])
      end
    end

    private

      def validate_procfile_v2(config)
        validate_command_params(config)
        config[:commands].values.each {|cmd| validate_command_params(cmd)}
      end

      def validate_command_params(cmd)
        validate_runlevel(cmd[:start_on_runlevel])
        validate_runlevel(cmd[:stop_on_runlevel])
        validate_path(cmd[:working_directory])
        validate_respawn(cmd[:respawn])
      end

      def validate_respawn(options)
        return unless options
        validate_digits(options[:kill_timeout])
        validate_digits(options[:interval])
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
        val = val.to_s
        return if val == ""

        unless val =~ regexp
          error("value #{val} is insecure and can't be accepted")
        end
      end

  end
end