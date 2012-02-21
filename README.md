Gem for exporting user-scripts as Upstart scripts
====================

[![Build Status](https://secure.travis-ci.org/savonarola/upstart-exporter.png)](http://travis-ci.org/savonarola/upstart-exporter)

Purpose
-------

It is often neccessary to run some supporting background tasks for rails projects alongside with the webserver. One of the solutions is use of Foreman gem, which allows to export tasks as Upstart scripts. This solution is dangerous, because it requires root priveleges for foreman executable (in order to add scripts to /etc/init), so it allows the exporting user to run any code as root (by placing appropriate script into /etc/init).

This gem is an attempt to provide a safe way for installing backround jobs, so that they run under some fixed user without root priveleges.

The only interface to the gem that should be used is the script(*upstart-export*) it provides.

Installing
----------

    gem install upstart-exporter


Configuration
-------------

The export process is configured through the only config, /etc/upstart-exporter.yaml, which is a simple YAML file of the following format:

    ---
    run_user: www # The user under which all installed through upstart-exporter background jobs are run 
    run_group: www # The group of run_user
    helper_dir: /var/helper_dir # Auxilary directory for scripts incapsulating background jobs
    upstart_dir: /var/upstart_dir # Directory where upstart scripts should be placed
    prefix: 'myupstartjobs-' # Prefix added to app's log folders and upstart scripts

The config is not installed by default. If this config is absent, the default values are the following:
    
    helper_dir: /var/local/upstart_helpers/
    upstart_dir: /etc/init/
    run_user: service
    prefix: 'fb-'

To give a certain user (i.e. deployuser) ability to use this script, one can place the following lines into sudoers file:
    
    # Commands required for manipulating jobs
    Cmnd_Alias UPSTART = /sbin/start, /sbin/stop, /sbin/restart
    Cmnd_Alias UPEXPORT = /usr/local/bin/upstart-export

    ...

    # Add gem's binary path to this
    Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

    ...

    # Allow deploy user to manipulate jobs 
    deployuser        ALL=(deployuser) NOPASSWD: ALL, (root) NOPASSWD: UPSTART, UPEXPORT
    

Usage
-----

After upstart-exporter is installed and configured, one may export background jobs from an arbitrary Procfile-like file of the following format:

    cmdlabel1: cmd1
    cmdlabel2: cmd2
    
i.e. a file ./myprocfile containing:

    my_tail_cmd: /usr/bin/tail -F /var/log/messages
    my_another_tail_cmd: /usr/bin/tail -F /var/log/messages

For security purposes, command labels are allowed to contain only letters, digits and underscores.

To export this file one should run
    
    sudo upstart-export -p ./myprocfile -n myapp

where _myapp_ is the application name. This name only affects the names of generated files. For security purposes, app name is also allowed to contain only letters, digits and underscores. Assuming that default options are used, the following files and folders will be generated:

in /etc/init/:

    fb-myapp-my_another_tail_cmd.conf
    fb-myapp-my_tail_cmd.conf
    fb-myapp.conf

in /var/local/upstart\_helpers/:

    fb-myapp-my_another_tail_cmd.sh
    fb-myapp-my_tail_cmd.sh

Prefix 'fb-' (which can be customised through config) is added to avoid collisions with other upstart jobs. After this my\_tail\_cmd, for example, will be able to be started as an upstart script:

    sudo start fb-myapp-my_tail_cmd

    ..

    sudo stop fb-myapp-my_tail_cmd

It's stdout/stderr will be redirected to /var/log/fb-myapp/my\_tail\_cmd.log.   

To start/stop all application commands at once, one can run:
    
    sudo start fb-myapp
    ...
    sudo stop fb-myapp

To remove upstart scripts and helpers for a particular application one can run

    sudo upstart-export -c -n myapp

The logs are not cleared in this case. Also, all old application scripts are cleared before each export.
