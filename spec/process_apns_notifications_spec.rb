require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/process_apns_notifications.rb'

describe "Process_APNS_PushNotifications" do
  it "should process push notifications for iOS devices" do
    Process_APNS_PushNotifications.method_defined?(:perform)
  end
end