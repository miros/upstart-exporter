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
      :app_name => 'appname',
      :commands => {
        'log' => 'public.log',
        'working_directory' => '/',
        'commands' => {
          'rm1' => {
            'command' => 'rm *',
            'log' => 'private.log'
          },
          'rm2' => {
            'command' => 'rm -rf *',
            'working_directory' => '/home'
          }
        }
      }
    }.merge(@defaults)
    Upstart::Exporter::Templates.should_receive(:helper) do |options|
      options.should include('working_directory' => '/')
      options.should include('log' => 'private.log')
      options.should include(:exec_cmd => "cd '/' && exec rm * >> private.log 2>&1")
    end
    Upstart::Exporter::Templates.should_receive(:helper) do |options|
      options.should include('working_directory' => '/home')
      options.should include('log' => 'public.log')
      options.should include(:exec_cmd => "cd '/home' && exec rm -rf * >> public.log 2>&1")
    end
    described_class.export(options)
  end
end
