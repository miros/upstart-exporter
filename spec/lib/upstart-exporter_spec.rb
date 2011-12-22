require 'spec/spec_helper'

describe Upstart::Exporter do
  let(:tpl){ Upstart::Exporter::Templates }

  let(:exporter) do
    make_global_config({
      'helper_dir' => '/h',
      'upstart_dir' => '/u',
      'run_user' => 'u',
      'prefix' => 'p-'
    }.to_yaml)
    make_procfile('Procfile', 'ls_cmd: ls')
    exporter = described_class.new({:app_name => 'app', :procfile => 'Procfile'})
  end

  describe '#export' do
    it 'should make cleanup before export' do
      exporter.should_receive(:clear)
      exporter.export
    end

    it 'should create upstart scripts, folders and sh helpers' do
      exporter.export
      %w{/h/p-app-ls_cmd.sh /u/p-app.conf /u/p-app-ls_cmd.conf}.each do |f|
        FileTest.file?(f).should be_true
      end
    end
    
    it 'created scripts, folders and sh helpers should have valid content' do
      exporter.export

      File.read('/h/p-app-ls_cmd.sh').should == tpl.helper(:cmd => ' ls')
      File.read('/u/p-app.conf').should == tpl.app(:run_user => 'u', :app_name => 'p-app')
      File.read('/u/p-app-ls_cmd.conf').should == tpl.command(:run_user => 'u', :app_name => 'p-app', :cmd_name => 'ls_cmd', :helper_cmd_conf => '/h/p-app-ls_cmd.sh')
    end
  end

  describe '#clear' do
    it 'should remove exported app helpers an scripts' do
      exporter.export
      exporter.clear
      Dir['/h/*'].should be_empty
      Dir['/u/*'].should be_empty
    end
    
    it 'should keep files of other apps' do
      exporter.export
      
      make_procfile('Procfile1', 'ls_cmd: ls')
      other_exporter = described_class.new({:app_name => 'other_app', :procfile => 'Procfile1'})
      other_exporter.export

      exporter.clear

      %w{/h/p-other_app-ls_cmd.sh /u/p-other_app.conf /u/p-other_app-ls_cmd.conf}.each do |f|
        FileTest.file?(f).should be_true
      end
    end
  end

end

