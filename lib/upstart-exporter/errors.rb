class Upstart::Exporter::Error < RuntimeError
end

module Upstart::Exporter::Errors
  def error(msg)
    raise Upstart::Exporter::Error, msg
  end

  def log(msg)
    $stdout.puts(msg)
  end
end



