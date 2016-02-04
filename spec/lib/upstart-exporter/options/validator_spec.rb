require 'spec/spec_helper'

describe Upstart::Exporter::Options::Validator do

  it "validates paths" do
    validator = described_class.new(:helper_dir => "/some/dir;")
    expect {validator.validate!}.to raise_error(Upstart::Exporter::Error)
  end

  it "validates user names" do
    validator = described_class.new(:run_user => "bad_user_name!")
    expect {validator.validate!}.to raise_error(Upstart::Exporter::Error)
  end

  it "validates runlevels" do
    validator = described_class.new(:start_on_runlevel => "[not_a_digit]")
    expect {validator.validate!}.to raise_error(Upstart::Exporter::Error)
  end

  describe "procfile v2" do
    it "validates respawn" do
      options = {:procfile_commands => {:version => 2, :respawn => {:kill_timeout => "10;"}}}
      validator = described_class.new(options)
      expect {validator.validate!}.to raise_error(Upstart::Exporter::Error)
    end

    it "validates options for individual commands" do
      options = {
        :procfile_commands => {:version => 2,
          :commands => {
            :come_cmd => {
              :working_directory => "!!!wrong_working-directory"
            }
          }
        }
      }
      validator = described_class.new(options)
      expect {validator.validate!}.to raise_error(Upstart::Exporter::Error)
    end
  end

end
