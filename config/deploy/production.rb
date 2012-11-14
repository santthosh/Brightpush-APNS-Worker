set :branch, "master"

role :web, "ec2-54-245-20-166.us-west-2.compute.amazonaws.com", "ec2-54-245-76-14.us-west-2.compute.amazonaws.com"                         # Your HTTP server, Apache/etc
role :app, "ec2-54-245-20-166.us-west-2.compute.amazonaws.com"                          # This may be the same as your `Web` server

set :rack_env,"production"

ssh_options[:user] = "ubuntu"
ssh_options[:keys] = ["/data/ops/alpha/aws-keys/us-west-oregon/brightpush-workers.pem"]

set :bucket_name,"brightpush_ios_certificates_pem"
set :aws_access_key_id,"AKIAIERRYQXDX7KCTHPQ"
set :aws_secret_access_key,"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"