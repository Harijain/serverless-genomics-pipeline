Serverless Genomics Analysis Pipeline on AWS
A fully automated, production-grade, 3-step bioinformatics pipeline on AWS, deployed and managed entirely with Terraform.

Project Overview
The cost of DNA sequencing has plummeted, but the real challenge for scientists is processing the massive datasets produced. This project solves that problem by creating a cost-effective, scalable, and serverless platform to run complex genomics analysis without requiring deep cloud infrastructure expertise.

Architecture
The pipeline is orchestrated by AWS Step Functions, managing a series of containerized jobs on AWS Batch. This serverless approach ensures that compute resources are only provisioned when a job is active, making the solution highly cost-efficient. The entire infrastructure is defined as code using Terraform.

**

Tech Stack
Orchestration: AWS Step Functions

Serverless Compute: AWS Batch

Containerization: Docker

Container Registry: Amazon ECR

Storage: Amazon S3

Permissions: AWS IAM

Infrastructure as Code (IaC): Terraform

Final Workflow
The state machine orchestrates a 3-step bioinformatics workflow:

Quality Control (FastQC): A fully functional job that runs the fastqc tool on a given input file.

Alignment (BWA): A functional job that uses a self-hosted reference genome to run the bwa mem alignment tool.

Variant Calling (GATK): A placeholder job that demonstrates the completion of the 3-step orchestration, ready for the real GATK tool to be dropped in.

Setup & Deployment
The entire AWS infrastructure for this project is managed by Terraform.

Prerequisites:

An AWS account with configured credentials.

Terraform installed.

Docker installed.

Deploy the Infrastructure:

Bash

# Navigate to the Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Apply the configuration to build all AWS resources
terraform apply
Push the Worker Images:
Once the ECR repositories are created by Terraform, build and push the Docker images from their respective workers subdirectories.

How to Run the Pipeline
Navigate to the AWS Step Functions console and find the Genomics-Pipeline-from-Terraform state machine.

Click "Start execution".

Provide an input JSON specifying the input data, output location, and a sample name.

JSON

{
  "InputS3Uri": "s3://your-input-bucket/your-test-file.txt",
  "OutputS3Uri": "s3://your-results-bucket/",
  "SampleName": "my-pipeline-test"
}
The pipeline will run, and the final analysis reports will be saved in your specified S3 results bucket.

Key Learnings & Debugging Journey
This project involved solving several real-world engineering problems, providing deep practical experience:

404 Not Found S3 Error: Solved a persistent access error by discovering that a public S3 bucket was a "Requester Pays" bucket, which required adding a --request-payer flag to all AWS CLI commands.

Task failed to start in AWS Batch: Debugged a complex IAM issue by identifying the critical difference between the Job Role (for application permissions like S3 access) and the Execution Role (for system permissions like pulling from ECR).

Terraform Versioning Conflicts: Solved multiple Unexpected attribute errors by locking the AWS provider version in the configuration and updating the resource syntax to match modern standards.

Docker ENTRYPOINT vs. CMD: Refactored the Docker containers to be more flexible by removing a hardcoded ENTRYPOINT, allowing them to be used as general-purpose workers that can run any command.

Step Functions Parameter Passing: Mastered the Amazon States Language (ASL) syntax, specifically using "Command.$": "States.Array(...)", to dynamically pass parameters from the state machine's input to the container's command.

Screenshots of project :
<img width="1920" height="1080" alt="Workflow" src="https://github.com/user-attachments/assets/fc7b90d5-89b5-4997-9aaf-0f599c77d74d" />
<img width="1920" height="1080" alt="Result" src="https://github.com/user-attachments/assets/4f34c35f-390a-4df0-96b1-afee961640f7" />

