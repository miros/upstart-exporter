module Upstart
  class Exporter
    class HashUtils

      def self.symbolize_keys(obj)
        case obj
          when Hash
            Hash[
              obj.map do |key, value|
                [key.respond_to?(:to_sym) ? key.to_sym : key, symbolize_keys(value)]
              end
            ]
          when Array
            obj.map {|value| symbolize_keys(value)}
          else
            obj
        end
      end

    end
  end
end