curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
python /tmp/get-pip.py && \
pip install awscli && \
aws configure set default.region ${AWS_REGION} && \
aws deploy push --application-name ${AWS_CODEDEPLOY_APP} --s3-location s3://${AWS_S3_BUCKET}/packages/${BITBUCKET_COMMIT}.zip --ignore-hidden-files && \
aws deploy create-deployment --application-name ${AWS_CODEDEPLOY_APP} --s3-location bucket=${AWS_S3_BUCKET},key=packages/${BITBUCKET_COMMIT}.zip,bundleType=zip --deployment-group-name ${AWS_CODEDEPLOY_GROUP}
