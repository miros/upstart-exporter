require 'spec/spec_helper'

describe Upstart::Exporter::Templates do
  describe ".app" do
    it "should generate a valid app config" do

      conf = <<-HEREDOC
start on 12
stop on 13

pre-start script

bash << "EOF"
  mkdir -p /var/log/SOMEAPP
  chown -R SOMEUSER /var/log/SOMEAPP
  chgrp -R SOMEGROUP /var/log/SOMEAPP
  chmod -R g+w /var/log/SOMEAPP
EOF

end script
HEREDOC

      described_class.app(
        :run_user => 'SOMEUSER', 
        :run_group => 'SOMEGROUP', 
        :app_name => 'SOMEAPP',
        :start_on => '12',
        :stop_on => '13'
      ).should == conf
    end
  end

  describe ".helper" do
    it "should generate a valid helper script" do

      conf = <<-HEREDOC
#!/bin/bash
if [ -f /etc/profile.d/rbenv.sh ]; then
  source /etc/profile.d/rbenv.sh
fi
SOME COMMAND
HEREDOC

      described_class.helper(:cmd => 'SOME COMMAND').should == conf
    end
  end


  describe ".helper" do
    it "should generate a valid upstart script for a single command" do

      conf = <<-HEREDOC
start on starting SOMEAPP
stop on stopping SOMEAPP
respawn
respawn limit 5 10

script
  touch /var/log/SOMEAPP/SOMECMD.log
  chown SOMEUSER /var/log/SOMEAPP/SOMECMD.log
  chgrp SOMEGROUP /var/log/SOMEAPP/SOMECMD.log
  chmod g+w /var/log/SOMEAPP/SOMECMD.log
  exec sudo -u SOMEUSER /bin/sh HELPERPATH >> /var/log/SOMEAPP/SOMECMD.log 2>&1
end script
HEREDOC

      described_class.command(:run_user => 'SOMEUSER',
                              :run_group => 'SOMEGROUP',
                              :app_name => 'SOMEAPP',
                              :cmd_name => 'SOMECMD',
                              :respawn => 'respawn',
                              :respawn_limit => 'respawn limit 5 10',
                              :start_on => 'starting SOMEAPP',
                              :stop_on => 'stopping SOMEAPP',
                              :helper_cmd_conf => 'HELPERPATH').should == conf
    end
  end



end

