module Upstart::Exporter::Options
  class CommandLine < Hash
    include Upstart::Exporter::Errors

    def initialize(command_line_args)
      super
      self[:commands] = if command_line_args[:clear]
        {}
      else
        process_procfile(command_line_args[:procfile])
      end
      self[:app_name] = process_appname(command_line_args[:app_name])
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
        elsif line =~ /^\s*#/
          # do nothing, comment
        elsif line =~ /^\s*$/
          # do nothing, empty
        else
          break if commands['version'] && commands['version'].strip == '2'
          error "procfile version 1 lines should have the following format: 'some_label: command'"
        end
      end
      if commands['version'] && commands['version'].strip == '2'
        commands = YAML.load(content)
        error('procfile should include "commands" key') unless commands['commands']
        error('command names should include only letters and/or underscores') if commands['commands'].keys.find { |k| k !~ /\A[A-z\d_]*?\z/ }
      end
      commands
    end

    def process_appname(app_name)
      error "Application name should contain only letters (and underscore) and be nonempty, so #{app_name.inspect} is not suitable" unless app_name =~ /^\w+$/
      app_name
    end

  end
end

