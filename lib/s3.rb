require 'aws'
require 'yaml'

# Helper class to manage simple_db
class S3
  $config = YAML.load_file("config/aws.yml")
  
  def self.mounted_certificate_path
    return $config[ENV['RACK_ENV']]["mounted_s3_certificate_bucket"]
  end
end