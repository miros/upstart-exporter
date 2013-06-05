require 'spec/spec_helper'

describe Upstart::Exporter::Templates do
  describe ".app" do
    it "should generate a valid app config" do

      conf = <<-HEREDOC
pre-start script

bash << "EOF"
  mkdir -p /var/log/SOMEAPP
  chown -R SOMEUSER /var/log/SOMEAPP
  chgrp -R SOMEGROUP /var/log/SOMEAPP
  chmod -R g+w /var/log/SOMEAPP
EOF

end script
HEREDOC

      described_class.app(:run_user => 'SOMEUSER', :run_group => 'SOMEGROUP', :app_name => 'SOMEAPP').should == conf
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

script
  touch /var/log/SOMEAPP/SOMECMD.log
  chown SOMEUSER /var/log/SOMEAPP/SOMECMD.log
  chgrp SOMEGROUP /var/log/SOMEAPP/SOMECMD.log
  chmod g+w /var/log/SOMEAPP/SOMECMD.log
  exec sudo -u SOMEUSER /bin/sh HELPERPATH >> /var/log/SOMEAPP/SOMECMD.log 2>&1
end script
HEREDOC

      described_class.command(:run_user => 'SOMEUSER', :run_group => 'SOMEGROUP', :app_name => 'SOMEAPP', :cmd_name => 'SOMECMD', :helper_cmd_conf => 'HELPERPATH').should == conf
    end
  end



end

