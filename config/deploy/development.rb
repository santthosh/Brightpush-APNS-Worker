set :branch, "develop"

role :web, "ec2-50-112-19-186.us-west-2.compute.amazonaws.com"                          # Your HTTP server, Apache/etc
role :app, "ec2-50-112-19-186.us-west-2.compute.amazonaws.com"                          # This may be the same as your `Web` server

ssh_options[:user] = "ubuntu"
ssh_options[:keys] = ["/data/ops/aws-keys/us-west-oregon/brightpush-workers.pem"]

set :bucket_name,"alpha_brightpush_ios_certificates_pem"
set :aws_access_key_id,"AKIAIERRYQXDX7KCTHPQ"
set :aws_secret_access_key,"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"