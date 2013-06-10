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
      options[:cmd].should == 'env B=b T=t  ls'
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
end
