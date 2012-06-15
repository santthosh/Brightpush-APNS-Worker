set :branch, "develop"

role :web, "ec2-50-112-19-186.us-west-2.compute.amazonaws.com"                          # Your HTTP server, Apache/etc
role :app, "ec2-50-112-19-186.us-west-2.compute.amazonaws.com"                          # This may be the same as your `Web` server

ssh_options[:user] = "ubuntu"
ssh_options[:keys] = ["/data/ops/aws-keys/us-west-oregon/brightpush-workers.pem"]