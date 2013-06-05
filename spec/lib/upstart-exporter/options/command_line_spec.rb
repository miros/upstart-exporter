require 'spec/spec_helper'

describe Upstart::Exporter::Options::CommandLine do
  context "when correct options are given" do
    it "should give access to options like a hash" do
        make_procfile('Procfile', 'ls_cmd: ls')
        described_class.new(:app_name => 'someappname', :procfile => 'Procfile').should respond_to('[]')
    end

    it "should parse procfile" do
        make_procfile('Procfile', 'ls_cmd: ls')
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        options[:commands].should == {'ls_cmd' => ' ls'}
    end

    it "should skip empty and commented lines in a procfile" do
        make_procfile('Procfile', "ls_cmd1: ls1\n\nls_cmd2: ls2\n # fooo baaar")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        options[:commands].should == {'ls_cmd1' => ' ls1', 'ls_cmd2' => ' ls2'}
    end

    it "should store app_name" do
        make_procfile('Procfile', "ls_cmd1: ls1\n\nls_cmd2: ls2\n # fooo baaar")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        options[:app_name].should == 'someappname'
    end

    it "should not process procfile if :clear arg is present" do
        make_procfile('Procfile', "bad procfile")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile', :clear => true)
        options[:app_name].should == 'someappname'
        options[:commands].should == {}
    end
  end

  context "when bad app_name is passed" do
    it "should raise exception" do
      make_procfile('Procfile', 'ls_cmd: ls')
      lambda{ described_class.new(:app_name => 'some appname', :procfile => 'Procfile') }.should raise_exception
      lambda{ described_class.new(:app_name => '-someappname', :procfile => 'Procfile') }.should raise_exception
      lambda{ described_class.new(:procfile => 'Procfile') }.should raise_exception
    end
  end

  context "when bad Procfile is passed" do
    it "should raise exception" do
      make_procfile('Procfile', 'ls cmd: ls')
      lambda{ described_class.new(:app_name => 'someappname', :procfile => 'Procfile') }.should raise_exception

      make_procfile('Procfile', '-lscmd: ls')
      lambda{ described_class.new(:app_name => 'someappname', :procfile => 'Procfile') }.should raise_exception

      lambda{ described_class.new(:app_name => 'someappname', :procfile => '::') }.should raise_exception

      lambda{ described_class.new(:app_name => 'someappname') }.should raise_exception
    end
  end


end

