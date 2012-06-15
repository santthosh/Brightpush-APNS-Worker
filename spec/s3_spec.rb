require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/s3.rb'

describe "S3" do
  it "should provide functionality for getting mounted certificate path in s3" do
    S3.method_defined?(:mounted_certificate_path)
  end
end