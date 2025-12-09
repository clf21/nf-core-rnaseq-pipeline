#!/bin/bash
# AWS Batch Setup Helper for nf-core/rnaseq pipeline
# This script helps configure AWS Batch for Nextflow execution

set -euo pipefail

cat << "EOF"
=============================================================================
AWS Batch Setup for nf-core/rnaseq Pipeline
=============================================================================

This script will guide you through setting up AWS Batch for running the
nf-core/rnaseq pipeline with Nextflow.

Prerequisites:
1. AWS CLI installed and configured
2. Appropriate IAM permissions for Batch, EC2, S3, and IAM
3. A VPC with subnets (default VPC is fine)

EOF

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not found. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

echo "✓ AWS CLI configured"
echo ""

# Get AWS account and region
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")

echo "AWS Account: $AWS_ACCOUNT"
echo "AWS Region: $AWS_REGION"
echo ""

# Configuration variables
COMPUTE_ENV_NAME="nf-core-rnaseq-compute-env"
JOB_QUEUE_NAME="nf-core-rnaseq-queue"
S3_BUCKET_NAME="nf-core-rnaseq-${AWS_ACCOUNT}"

cat << EOF
=============================================================================
Configuration Summary
=============================================================================
Compute Environment: $COMPUTE_ENV_NAME
Job Queue: $JOB_QUEUE_NAME
S3 Bucket: $S3_BUCKET_NAME
Region: $AWS_REGION

This script will:
1. Create IAM roles for AWS Batch
2. Create an AWS Batch Compute Environment (EC2 Spot instances)
3. Create an AWS Batch Job Queue
4. Create an S3 bucket for work files
5. Update your nextflow.config with these values

EOF

read -p "Proceed with setup? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy]es$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "=============================================================================
Starting setup...
============================================================================="

# 1. Create IAM role for Batch service
echo "Creating IAM roles..."

cat > batch-service-role-trust.json << 'TRUST_POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "batch.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
TRUST_POLICY

aws iam create-role \
    --role-name AWSBatchServiceRole \
    --assume-role-policy-document file://batch-service-role-trust.json \
    2>/dev/null || echo "Service role already exists"

aws iam attach-role-policy \
    --role-name AWSBatchServiceRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole \
    2>/dev/null || true

# 2. Create IAM role for ECS instances
cat > ecs-instance-role-trust.json << 'ECS_TRUST'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
ECS_TRUST

aws iam create-role \
    --role-name ecsInstanceRole \
    --assume-role-policy-document file://ecs-instance-role-trust.json \
    2>/dev/null || echo "ECS instance role already exists"

aws iam attach-role-policy \
    --role-name ecsInstanceRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role \
    2>/dev/null || true

# Create instance profile
aws iam create-instance-profile \
    --instance-profile-name ecsInstanceRole \
    2>/dev/null || echo "Instance profile already exists"

aws iam add-role-to-instance-profile \
    --instance-profile-name ecsInstanceRole \
    --role-name ecsInstanceRole \
    2>/dev/null || true

echo "✓ IAM roles created"

# 3. Create S3 bucket
echo "Creating S3 bucket..."
aws s3 mb s3://$S3_BUCKET_NAME --region $AWS_REGION 2>/dev/null || echo "Bucket already exists"
echo "✓ S3 bucket ready: s3://$S3_BUCKET_NAME"

# 4. Get default VPC and subnets
echo "Getting VPC configuration..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text | tr '\t' ',')

echo "VPC: $VPC_ID"
echo "Subnets: $SUBNET_IDS"

# 5. Create security group
echo "Creating security group..."
SG_ID=$(aws ec2 create-security-group \
    --group-name nf-core-batch-sg \
    --description "Security group for nf-core Batch compute environment" \
    --vpc-id $VPC_ID \
    --output text 2>/dev/null || aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=nf-core-batch-sg" --query "SecurityGroups[0].GroupId" --output text)

echo "✓ Security group: $SG_ID"

# 6. Create Batch Compute Environment
echo "Creating AWS Batch Compute Environment..."

cat > compute-env.json << ENV_JSON
{
  "computeEnvironmentName": "$COMPUTE_ENV_NAME",
  "type": "MANAGED",
  "state": "ENABLED",
  "computeResources": {
    "type": "SPOT",
    "allocationStrategy": "SPOT_CAPACITY_OPTIMIZED",
    "minvCpus": 0,
    "maxvCpus": 256,
    "desiredvCpus": 0,
    "instanceTypes": ["optimal"],
    "subnets": ["${SUBNET_IDS//,/\",\"}"],
    "securityGroupIds": ["$SG_ID"],
    "instanceRole": "arn:aws:iam::$AWS_ACCOUNT:instance-profile/ecsInstanceRole",
    "spotIamFleetRole": "arn:aws:iam::$AWS_ACCOUNT:role/aws-ec2-spot-fleet-tagging-role"
  },
  "serviceRole": "arn:aws:iam::$AWS_ACCOUNT:role/AWSBatchServiceRole"
}
ENV_JSON

aws batch create-compute-environment --cli-input-json file://compute-env.json 2>/dev/null || \
    echo "Compute environment already exists"

echo "✓ Compute environment created"

# 7. Create Job Queue
echo "Creating AWS Batch Job Queue..."

aws batch create-job-queue \
    --job-queue-name $JOB_QUEUE_NAME \
    --state ENABLED \
    --priority 1 \
    --compute-environment-order order=1,computeEnvironment=$COMPUTE_ENV_NAME \
    2>/dev/null || echo "Job queue already exists"

echo "✓ Job queue created"

# 8. Update nextflow.config
echo ""
echo "=============================================================================
Setup Complete!
============================================================================="
echo ""
echo "Your AWS Batch resources are ready:"
echo "  • Compute Environment: $COMPUTE_ENV_NAME"
echo "  • Job Queue: $JOB_QUEUE_NAME"
echo "  • S3 Work Directory: s3://$S3_BUCKET_NAME/work"
echo ""
echo "Update your nextflow.config with these values:"
echo ""
echo "  process.queue = '$JOB_QUEUE_NAME'"
echo "  workDir = 's3://$S3_BUCKET_NAME/work'"
echo "  aws.region = '$AWS_REGION'"
echo ""
echo "Run your pipeline with:"
echo "  nextflow run nf-core/rnaseq -profile aws \\"
echo "    --input samplesheet.csv \\"
echo "    --genome GRCh38 \\"
echo "    --outdir s3://$S3_BUCKET_NAME/results"
echo ""

# Cleanup temp files
rm -f batch-service-role-trust.json ecs-instance-role-trust.json compute-env.json

echo "Setup script completed!"
