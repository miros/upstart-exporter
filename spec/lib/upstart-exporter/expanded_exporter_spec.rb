require 'spec/spec_helper'

describe Upstart::Exporter::ExpandedExporter do
  before do
    @defaults = {}
    Upstart::Exporter::Options::Global::DEFAULTS.each do |key, value|
      @defaults[key.to_sym] = value
    end

    File.stub(:open)
  end

  it 'calls template render exact amount of times' do
    Upstart::Exporter::Templates.should_receive(:command).exactly(5).times
    options = {
      :commands => {
        'commands' => {
          'ls' => {
            'command' => 'ls',
            'count' => 3
          },
          'ls2' => {
            'command' => 'ls',
            'count' => 2
          }
        }
      },
      :app_name => 'appname'
    }.merge(@defaults)

    described_class.export(options)
  end

  it 'merges env params in the right order' do
    Upstart::Exporter::Templates.should_receive(:helper) do |options|
      options[:cmd].should include('B=b')
      options[:cmd].should include('T=t')
    end
    options = {
      :commands => {
        'env' => {
          'T' => 't',
          'B' => 'a'
        },
        'commands' => {
          'ls' => {
            'command' => 'ls',
            'env' => {
              'B' => 'b'
            }
          }
        }
      },
      :app_name => 'appname'
    }.merge(@defaults)

    described_class.export(options)
  end

  it 'passes all calculated binds to the helper exporter' do
    options = {
      :version => 2,
      :app_name => 'appname',
      :working_directory => "/",
      :log => "public.log",
      :commands => {
        'working_directory' => '/var/log',
        'commands' => {
          'rm1' => {
            'command' => 'rm *',
            'log' => 'private.log'
          },
          'rm2' => {
            'command' => 'rm -rf *',
            'working_directory' => '/home'
          },
          'rm3' => {
            'command' => 'rm -f vmlinuz',
          }
        }
      }
    }.merge(@defaults)
    Upstart::Exporter::Templates.should_receive(:helper) do |options|
      options.should include('working_directory' => '/var/log') # propagated from 'commands'
      options.should include('log' => 'private.log')            # redefined by command
      options.should include(:exec_cmd => "cd '/var/log' && exec rm * >> private.log 2>&1")
    end
    Upstart::Exporter::Templates.should_receive(:helper) do |options|
      options.should include('working_directory' => '/home')    # redefined by command
      options.should include('log' => 'public.log')             # propagated from the very top level
      options.should include(:exec_cmd => "cd '/home' && exec rm -rf * >> public.log 2>&1")
    end
    Upstart::Exporter::Templates.should_receive(:helper) do |options|
      options.should include('working_directory' => '/var/log') # propagated from 'commands'
      options.should include('log' => 'public.log')             # propagated from the very top level
      options.should include(:exec_cmd => "cd '/var/log' && exec rm -f vmlinuz >> public.log 2>&1")
    end
    described_class.export(options)
  end
end
