# Deploying an autoscaled Laravel app from Bitbucket to AWS CodeDeploy

Here are the steps and supporting files needed to deploy Laravel applications from Bitbucket to an autoscaled production environment at AWS. Deployment is handled through Bitbucket Pipelines, from where it moves to AWS CodeDeploy, which places new revisions to instances in an Auto Scaling Group.

This is mostly sample content so tweak to your app's needs. The EC2 instances in this setup use Amazon Linux AMI and will have Apache, PHP and the modules Laravel requires out-of-the-box. The app is deployed to `/var/www/app` and the usual optimization commands are run during each deployment.

## AWS services used

- S3 bucket
    - Stores the deployment package
    - Stores resources for setting up instances
- IAM user for Bitbucket
    - Allows uploading the deployment package to S3
    - Allows interacting with CodeDeploy
- IAM service role for EC2 instances
    - Allows reading the S3 bucket
- IAM service role for CodeDeploy
    - Allows managing the CodeDeploy app
- EC2 Application Load Balancer + Target Group
- EC2 Launch Configuration + Auto Scaling Group
- CodeDeploy Application

## Setup

These steps assume you either know your way around these parts or are open to reading the instructions AWS gives you at each step.

1. **Your app**
    1. Include the files `bitbucket-pipelines.yml`, `bitbucket-pipelines-codedeploy.sh`, `bitbucket-pipelines-common.sh`, `appspec.yml`, `codedeploy-prepare.sh` and `codedeploy-setup-app.sh` from this repository to your app's root directory.
1. **S3**
    1. Create a bucket. This tutorial will use the name `bitbucket-pipelines-bucket`.
    1. Upload an Apache configuration file. See example configuration (*production.apache.conf*) below.
    1. Upload a dotenv file for Laravel. See example (*production.env*) below.
1. **IAM**
    1. Create a **Policy** using *Create Your Own Policy*. This tutorial will use the name `bitbucket-pipelines-deploy-with-codedeploy`. Use the JSON below.
    1. Create a **Policy** using *Create Your Own Policy*. This tutorial will use the name `bitbucket-pipelines-manage-app-zip`. Use the JSON below.
    1. Create a **Policy** using *Create Your Own Policy*. This tutorial will use the name `bitbucket-pipelines-read-bucket`. Use the JSON below.
    1. Create a **User** for *Programmatic access*. This tutorial will use the name `bitbucket-pipelines-user`. Attach the `bitbucket-pipelines-deploy-with-codedeploy` and `bitbucket-pipelines-manage-app-zip` policies. Keep the generated keys for use in a later step.
    1. Create a **Role** for *EC2 (Service Role)*. This tutorial will use the name `bitbucket-pipelines-ec2-role`. Attach the `bitbucket-pipelines-read-bucket` policy.
    1. Create a **Role** for *CodeDeploy (Service Role)*. This tutorial will use the name `bitbucket-pipelines-codedeploy-role`. Attach the builtin `AWSCodeDeployRole` policy.
1. **EC2**
    1. Create an **Application Load Balancer**. This tutorial will use the name `bitbucket-pipelines-alb` for the ALB and `bitbucket-pipelines-tg` for the Target Group. Set a Health Check Path of `/health-check.php`. No need to register targets yet.
    1. Create a **Launch Configuration**. This tutorial will use the name `bitbucket-pipelines-lc`. Use the *User data* below and select the previosly created EC2 role.
    1. Create an **Auto Scaling Group**. This tutorial will use the name `bitbucket-pipelines-asg`. Set it to receive traffic from the previously created ALB.
1. **CodeDeploy**
    1. Create an **Application**. This tutorial will use the name `bitbucket-pipelines-codedeploy-app` for both the app and its group. Select `bitbucket-pipelines-asg` under Auto Scaling Groups. Check to *Enable load balancing*, then select `bitbucket-pipelines-tg` under Application Load Balancer. Use the `bitbucket-pipelines-codedeploy-role` role.
1. **Bitbucket**
    1. Enable Pipelines at your repository's Settings.
    1. Add the following to **Environment variables**:
        - AWS_ACCESS_KEY_ID: *use the access key from earlier*
        - AWS_SECRET_ACCESS_KEY: *use the secret key from earlier and remember to check **Secured***
        - AWS_REGION: *use the region you've set all this up in*
        - AWS_CODEDEPLOY_APP: `bitbucket-pipelines-codedeploy-app`
        - AWS_CODEDEPLOY_GROUP: `bitbucket-pipelines-codedeploy-app`
        - AWS_S3_BUCKET: `bitbucket-pipelines-bucket`
1. Push to master

## Config file "production.apache.conf"

```
<Directory /var/www/app>
  AllowOverride All
  Options FollowSymLinks
</Directory>

<VirtualHost *:80>
  DocumentRoot /var/www/html
</VirtualHost>

<VirtualHost *:80>
  ServerName app.dev

  DocumentRoot /var/www/app/public
</VirtualHost>
```

## Config file "production.env"

```
APP_ENV=production
APP_DEBUG=false
APP_KEY=your-generated-key-goes-here
APP_URL=http://localhost
```

## IAM policy "bitbucket-pipelines-deploy-with-codedeploy"

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:RegisterApplicationRevision",
                "codedeploy:CreateDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:GetApplicationRevision"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

## IAM policy, "bitbucket-pipelines-manage-app-zip"

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::bitbucket-pipelines-bucket/packages/*"
            ]
        }
    ]
}
```

## IAM policy, "bitbucket-pipelines-read-bucket"

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::bitbucket-pipelines-bucket/*"
            ]
        }
    ]
}
```

## EC2 Launch Configuration, User data

```sh
#!/bin/bash
yum update -y
yum install -y ruby wget httpd24 php70 php70-mbstring php70-pdo
wget https://aws-codedeploy-eu-west-1.s3.amazonaws.com/latest/install
chmod +x install
./install auto
aws s3 cp s3://bitbucket-pipelines-bucket/production.apache.conf /etc/httpd/conf.d/app.conf
touch /var/www/html/health-check.php
chkconfig httpd on
service httpd start
```
