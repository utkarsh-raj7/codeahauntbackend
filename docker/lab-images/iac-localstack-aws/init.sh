#!/bin/bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
alias aws='aws --endpoint-url http://localhost:4566'
echo "export AWS_ACCESS_KEY_ID=test" >> ~/.bashrc
echo "export AWS_SECRET_ACCESS_KEY=test" >> ~/.bashrc
echo "export AWS_DEFAULT_REGION=us-east-1" >> ~/.bashrc
echo "alias aws='aws --endpoint-url http://localhost:4566'" >> ~/.bashrc
echo "LocalStack AWS simulation ready"
echo "Try: aws s3 mb s3://my-bucket"
