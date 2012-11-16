require 'resque/tasks'
require 'sinatra'
import 'lib/simpledb.rb'
import 'lib/sqs.rb'
import 'lib/process_apns_notifications.rb'

task :default => :help

namespace :resque do
  task :setup do
    require 'resque'
    
    rack_env = ENV['RACK_ENV'] || 'local'

    if rack_env == 'production'
      $redis = 'redis.brightpush.in:6379'
    elsif rack_env == 'staging'
      $redis = 'redis.brightpushbeta.in:6379'
    elsif rack_env == 'development'
      $redis = 'redis.brightpushalpha.in:6379'
    else 
      $redis = 'localhost:6379'
    end
    
    puts $redis
    
    # Setup the shared redis server
    Resque.redis = $redis
  end
end

desc "Run specs"
task :spec do
  require 'rspec/core/rake_task'
  
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

desc "Run IRB console with app environment"
task :console do
  puts "Loading development console..."
  system("irb -r ./config/boot.rb")
end

desc "Show help menu"
task :help do
  puts "Available rake tasks: "
  puts "rake console - Run a IRB console with all enviroment loaded"
  puts "rake spec - Run specs and calculate coverage"
end