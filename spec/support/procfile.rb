def make_procfile(fname, content)
  File.open(fname, 'w') do |f|
    f.write content
  end
end
