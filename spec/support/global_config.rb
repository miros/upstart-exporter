def make_global_config(content)
  path =  Upstart::Exporter::Options::Global::CONF
  dir = File.dirname(path)
  FileUtils.mkdir_p(dir)
  File.open(path, 'w'){|f| f.write(content) }
end
