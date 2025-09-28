#!/bin/bash
# This script runs the BWA alignment.
# It takes 3 arguments: Input FASTQ S3 URI, Output S3 Path, Sample Name

set -e

INPUT_FASTQ_URI=$1
OUTPUT_S3_PATH=$2
SAMPLE_NAME=$3

echo "Starting BWA alignment for sample: ${SAMPLE_NAME}"

# For this test, we will use a small, public E. coli reference genome
REF_GENOME_S3_PATH="s3://ngi-igenomes/Escherichia_coli_K_12_DH10B/NCBI/2008-03-17/Sequence/BWAIndex/"

# Create local directories inside the container to work in
mkdir -p /tmp/data/input
mkdir -p /tmp/data/reference

# Download the input FASTQ file from the 1000genomes bucket
echo "Downloading FASTQ file..."
aws s3 cp ${INPUT_FASTQ_URI} /tmp/data/input/ --region us-east-1 --request-payer requester

# Download the reference genome index files
echo "Downloading reference genome..."
aws s3 sync ${REF_GENOME_S3_PATH} /tmp/data/reference/ --region us-east-1

LOCAL_FASTQ_FILE="/tmp/data/input/$(basename ${INPUT_FASTQ_URI})"

# Run the BWA mem alignment command
echo "Running BWA mem..."
bwa mem /tmp/data/reference/genome.fa ${LOCAL_FASTQ_FILE} > /tmp/data/${SAMPLE_NAME}.sam

# Upload the final SAM file to our results bucket
echo "Uploading SAM file to S3..."
aws s3 cp /tmp/data/${SAMPLE_NAME}.sam ${OUTPUT_S3_PATH} --region us-east-1

echo "BWA alignment complete."