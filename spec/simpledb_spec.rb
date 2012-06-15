require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/simpledb.rb'

describe "SimpleDB" do
  it "should provide functionality for getting SimpleDB domain" do
    SimpleDB.method_defined?(:get_domain)
  end
  
  it "should provide domain for notification queues" do
    SimpleDB.method_defined?(:domain_for_notification_queues)
  end
  
  it "should provide domain for notifications" do
    SimpleDB.method_defined?(:domain_for_notification)
  end
end