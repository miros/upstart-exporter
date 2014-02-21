require 'spec/spec_helper'

describe Upstart::Exporter do
  let(:tpl){ Upstart::Exporter::Templates }

  before do
    make_global_config({
      'helper_dir' => '/h',
      'upstart_dir' => '/u',
      'run_user' => 'u',
      'run_group' => 'g',
      'prefix' => 'p-',
      'start_on_runlevel' => '[7]'
    }.to_yaml)
    make_procfile('Procfile', 'ls_cmd: ls')
  end

  let(:exporter) do
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

      File.read('/h/p-app-ls_cmd.sh').should == tpl.helper(:cmd => 'exec ls')
      File.read('/u/p-app.conf').should == tpl.app(:run_user => 'u',
                                                   :run_group => 'g',
                                                   :app_name => 'p-app',
                                                   :start_on => 'runlevel [7]',
                                                   :stop_on => 'runlevel [3]')
      File.read('/u/p-app-ls_cmd.conf').should == tpl.command(:run_user => 'u',
                                                              :run_group => 'g',
                                                              :app_name => 'p-app',
                                                              :cmd_name => 'ls_cmd',
                                                              :start_on => 'starting p-app',
                                                              :stop_on => 'stopping p-app',
                                                              :respawn => 'respawn',
                                                              :respawn_limit => '',
                                                              :kill_timeout => 30,
                                                              :helper_cmd_conf => '/h/p-app-ls_cmd.sh')
    end

    it 'prepends with "env" command starts with env var assignment' do
      make_procfile('Procfile', 'sidekiq: RAILS_ENV=production sidekiq')
      exporter.export

      File.read('/h/p-app-sidekiq.sh').should == tpl.helper(:cmd => 'exec env RAILS_ENV=production sidekiq')
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

