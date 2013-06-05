module Upstart::Exporter::Options
  class ExpandedParser
    def self.parse(content)
      new(content).parse
    end

    def initialize(content)
      @content = content
    end

    def parse
      YAML.load(@content)
    end

  private
    def log(msg)
      if msg == :break
        $stdout.puts "\n"
      else
        $stdout.puts msg
      end
    end
  end
end
