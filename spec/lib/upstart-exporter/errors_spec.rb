require 'spec/spec_helper'

describe Upstart::Exporter::Errors do
  context "when included" do
    it "should provide #error method" do
      class Foo
        include Upstart::Exporter::Errors
      end

      Foo.new.should respond_to(:error)
    end
  end

  describe "#error" do
    it "should raise a correct exception" do
      class Foo
        include Upstart::Exporter::Errors
      end

      lambda{ Foo.new.error("arrgh") }.should raise_exception(Upstart::Exporter::Error)
    end
  end
end
