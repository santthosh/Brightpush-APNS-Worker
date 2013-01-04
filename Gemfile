source 'http://rubygems.org'

gem 'rake'
gem 'resque', :git => "git://github.com/santthosh/resque.git", :branch => '2.0+logging'
gem 'aws-sdk'
gem 'multi_json','1.3.5'
gem 'rack'
gem 'rake'
gem 'json'
gem 'grocer', :git => "git://github.com/santthosh/grocer.git", :branch => 'master'
gem 'resque-status', :git => "git://github.com/quirkey/resque-status.git", :branch => 'master'

group :development do
  gem 'capistrano', '2.8.0'
  gem 'capistrano-ext', '1.2.1'
  gem 'rvm-capistrano'
end

group :test, :development do
  gem "rspec", "~>2"
  gem "simplecov"
  gem 'rack-test', :require => "rack/test"
  gem 'webrat'
end
