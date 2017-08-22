# Prepares for the deployment. Called from CodeDeploy's appspec.yml.

touch /tmp/deployment-started

# Download the .env file from S3 before emptying the directory to shave
# off a few seconds of downtime in case we don't deregister the instance
# from the load balancer.
aws s3 cp s3://bitbucket-pipelines-bucket/production.env /tmp/production.env

# Completely empty the app directory before dumping the revision's files
# there to avoid any deployment failures.
rm -Rf /var/www/app/
mkdir /var/www/app/
chown apache:apache /var/www/app/

touch /tmp/deployment-cleared
