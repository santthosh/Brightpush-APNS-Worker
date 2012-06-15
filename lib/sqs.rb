require 'aws'
require 'yaml'

# Helper class to manage SQS
class SQS
  
  # Create an SQS queue
  def self.create_queue(identifier)
    config = YAML.load_file("config/aws.yml")
        
    client = AWS::SQS.new(
              :access_key_id => config[ENV['RACK_ENV']]["access_key_id"],
              :secret_access_key => config[ENV['RACK_ENV']]["secret_access_key"])

    return client.queues.create(identifier)
  end
  
  # Get an SQS queue
  def self.get_queue(identifier)
    config = YAML.load_file("config/aws.yml")
        
    client = AWS::SQS.new(
              :access_key_id => config[ENV['RACK_ENV']]["access_key_id"],
              :secret_access_key => config[ENV['RACK_ENV']]["secret_access_key"])

    return client.queues.named(identifier)
  end
  
end