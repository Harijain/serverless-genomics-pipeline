terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_ecr_repository" "fastqc_worker_repo" {
  name = "genomics/fastqc-worker"
}
resource "aws_ecr_repository" "bwa_worker_repo" {
  name = "genomics/bwa-worker"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceRole"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ECSTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "genomics_job_role" {
  name = "GenomicsJobRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "genomics_job_role_s3_read_policy" {
  role       = aws_iam_role.genomics_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_policy" "s3_write_policy" {
  name   = "AllowS3WriteToResultsBucket"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = ["s3:PutObject"],
      Effect   = "Allow",
      Resource = "${aws_s3_bucket.results_bucket.arn}/*"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "genomics_job_role_s3_write_policy" {
  role       = aws_iam_role.genomics_job_role.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}

resource "aws_s3_bucket" "results_bucket" {
  bucket = "genomics-pipeline-results-bhai-12345" # <-- IMPORTANT: Change this to a new unique bucket name!
}

resource "aws_batch_compute_environment" "genomics_ce" {
  compute_environment_name = "genomics-compute-env"
  service_role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch"
  type                     = "MANAGED"
  compute_resources {
    instance_role = aws_iam_instance_profile.ecs_instance_profile.arn
    instance_type = ["optimal"]
    max_vcpus     = 8
    min_vcpus     = 0
    security_group_ids = [data.aws_security_group.default.id]
    subnets            = data.aws_subnets.default.ids
    type               = "EC2"
  }
}

resource "aws_batch_job_queue" "genomics_jq" {
  name                 = "genomics-job-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.genomics_ce.arn]
}

resource "aws_batch_job_definition" "fastqc_job_def_final" {
  name = "fastqc-job-def-final"
  type = "container"
  container_properties = jsonencode({
    image            = "${aws_ecr_repository.fastqc_worker_repo.repository_url}:v8", # Make sure this tag exists in your ECR
    vcpus            = 1,
    memory           = 1024,
    jobRoleArn       = aws_iam_role.genomics_job_role.arn,
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
  })
}

resource "aws_batch_job_definition" "bwa_job_def_final" {
  name = "bwa-job-def-final"
  type = "container"
  container_properties = jsonencode({
    image            = "${aws_ecr_repository.bwa_worker_repo.repository_url}:v3", # Make sure this tag exists in your ECR
    vcpus            = 1,
    memory           = 2048,
    jobRoleArn       = aws_iam_role.genomics_job_role.arn,
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
  })
}

resource "aws_sfn_state_machine" "genomics_pipeline_sm" {
  name     = "Genomics-Pipeline-from-Terraform"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Final Genomics Pipeline - Deployed by Terraform"
    StartAt = "Run FastQC"
    States = {
      "Run FastQC" = {
        Type     = "Task"
        Resource = "arn:aws:states:::batch:submitJob.sync"
        Parameters = {
          JobName       = "FastQC-Execution"
          JobQueue      = aws_batch_job_queue.genomics_jq.arn
          JobDefinition = aws_batch_job_definition.fastqc_job_def_final.arn
          ContainerOverrides = {
            "Command.$" = "States.Array('run_fastqc.sh', $.InputS3Uri, $.OutputS3Uri)"
          }
        }
        ResultPath = "$.fastqc_result"
        Next       = "Run BWA"
      }
      "Run BWA" = {
        Type     = "Task"
        Resource = "arn:aws:states:::batch:submitJob.sync"
        Parameters = {
          JobName       = "BWA-Execution"
          JobQueue      = aws_batch_job_queue.genomics_jq.arn
          JobDefinition = aws_batch_job_definition.bwa_job_def_final.arn
          ContainerOverrides = {
            "Command.$" = "States.Array('run_bwa.sh', $.InputS3Uri, $.OutputS3Uri)"
          }
        }
        End = true
      }
    }
  })
}

resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctions-Genomics-Pipeline-Role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "StepFunctions-Genomics-Pipeline-Policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "batch:SubmitJob",
          "batch:DescribeJobs",
          "batch:TerminateJob"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ],
        Resource = "arn:aws:events:*:*:rule/StepFunctionsGetEventsForBatchJobsRule"
      }
    ]
  })
}