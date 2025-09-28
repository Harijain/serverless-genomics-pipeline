Serverless Genomics Analysis Pipeline on AWS.

An automated, scalable, and cost-effective pipeline for running complex bioinformatics workflows on AWS using serverless technologies.

## The Problem
In the world of life sciences, processing massive genomics datasets is slow, expensive, and complex. This project builds a production-grade platform to automate this analysis, allowing researchers to get from raw DNA data to meaningful results without needing to be cloud infrastructure experts.

## Architecture
The entire pipeline is orchestrated by AWS Step Functions, which manages a series of containerized jobs running on AWS Batch. This serverless approach ensures that compute resources are only used when a job is active, making the solution highly cost-efficient. The entire infrastructure is defined as code using Terraform.

## Tech Stack
Orchestration: AWS Step Functions

Serverless Compute: AWS Batch

Containerization: Docker

Container Registry: Amazon ECR

Storage: Amazon S3

Permissions: AWS IAM

Infrastructure as Code (IaC): Terraform

## Features
Fully Automated: The entire multi-step workflow is managed by a Step Functions state machine.

Scalable & Parallel: AWS Batch automatically scales the compute resources (EC2 instances) based on job demand.

Cost-Effective: With minvCpus = 0, the infrastructure costs nothing when idle.

Containerized Tools: All bioinformatics tools (FastQC, BWA) are packaged in Docker for portability and dependency management.

Infrastructure as Code: The entire AWS environment is defined in Terraform, allowing for one-command deployment and destruction.

## Project Structure
.
├── terraform/
│   └── main.tf         # The complete infrastructure definition
├── workers/
│   ├── fastqc-worker/
│   │   ├── Dockerfile
│   │   └── run_fastqc.sh
│   └── bwa-worker/
│       ├── Dockerfile
│       └── run_bwa.sh
└── README.md
## Setup & Deployment
The entire infrastructure can be deployed with a few commands.

Clone the repository:

Bash

git clone https://github.com/Harijain/serverless-genomics-pipeline.git
Navigate to the Terraform directory:

Bash

cd serverless-genomics-pipeline/terraform
Initialize Terraform:

Bash

terraform init
Apply the configuration:

Bash

terraform apply
(Note: You will need to have your AWS credentials configured for the AWS CLI).

## How to Use
Navigate to the AWS Step Functions console and find the Genomics-Pipeline-from-Terraform state machine.

Click "Start execution".

Provide an input JSON specifying the input data location and the output location.

JSON

{
  "InputS3Uri": "s3://1000genomes/phase3/data/HG00096/sequence_read/SRR062634.filt.fastq.gz",
  "OutputS3Uri": "s3://your-unique-results-bucket-name/"
}
The pipeline will run, and the final analysis reports will be saved in your specified S3 results bucket.

## Key Learnings & Challenges
This project involved solving several real-world engineering problems:

Persistent 404 Not Found S3 Error: Solved by discovering the public 1000genomes bucket is a "Requester Pays" bucket, which required adding a --request-payer flag to all AWS CLI S3 commands.

Task failed to start in AWS Batch: Debugged a complex IAM issue by differentiating between the Job Role (for application permissions like S3 access) and the Execution Role (for system permissions like pulling from ECR).

Terraform Versioning Conflicts: Solved multiple Unexpected attribute errors by locking the AWS provider version to ~> 5.0 in the Terraform configuration and correcting the resource syntax.

Docker ENTRYPOINT vs. CMD: Refactored the Docker containers to be more flexible by removing a hardcoded ENTRYPOINT, allowing them to be used as general-purpose workers.