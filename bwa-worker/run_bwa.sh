#!/bin/bash
set -e

INPUT_FASTQ_URI=$1
OUTPUT_S3_PATH=$2
SAMPLE_NAME=$3

echo "Starting BWA alignment for sample: ${SAMPLE_NAME}"

# This now points to YOUR OWN bucket
REF_GENOME_S3_PATH="s3://genomics-pipeline-reference-bhai-12345/fake_genome.fa"

# Create directories
mkdir -p /tmp/data/input
mkdir -p /tmp/data/reference

# Download the input file from your own bucket
echo "Downloading input file..."
aws s3 cp ${INPUT_FASTQ_URI} /tmp/data/input/ --region us-east-1

# Download the reference genome from your own bucket
echo "Downloading reference genome..."
aws s3 cp ${REF_GENOME_S3_PATH} /tmp/data/reference/ --region us-east-1

LOCAL_FASTQ_FILE="/tmp/data/input/$(basename ${INPUT_FASTQ_URI})"
LOCAL_REF_FILE="/tmp/data/reference/fake_genome.fa"

# Index the reference genome
echo "Indexing the reference genome..."
bwa index ${LOCAL_REF_FILE}

# Run the BWA mem alignment command
echo "Running BWA mem..."
bwa mem ${LOCAL_REF_FILE} ${LOCAL_FASTQ_FILE} > /tmp/data/${SAMPLE_NAME}.sam

# Upload the final SAM file to the results bucket
echo "Uploading SAM file to S3..."
aws s3 cp /tmp/data/${SAMPLE_NAME}.sam ${OUTPUT_S3_PATH} --region us-east-1

echo "BWA alignment complete."