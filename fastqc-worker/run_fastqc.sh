#!/bin/bash
set -e

# This script will download a file from S3, run FastQC, and upload the results to S3.
# Arguments:
# $1: Input S3 URI (eg. s3://bucket/key.fastq.gz)
# $2: Output S3 URI (eg. s3://bucket/results/)

INPUT_FILE_URI=$1
OUTPUT_RESULTS_URI=$2

echo "Input file is: $INPUT_FILE_URI"
echo "Output location is: $OUTPUT_RESULTS_URI"

# Download the input file from S3
aws s3 cp $INPUT_FILE_URI .

# Get the basename of the file
FILENAME=$(basename $INPUT_FILE_URI)

# Run FastQC on the downloaded file
/opt/FastQC/fastqc $FILENAME

# The output will be a .zip and a .html file. We'll upload the html.
# Remove the .fastq.gz extension to get the base name for the output
BASENAME=${FILENAME%.fastq.gz}

# Upload the HTML report to our S3 bucket
aws s3 cp ${BASENAME}_fastqc.html $OUTPUT_RESULTS_URI

echo "Job completed successfully."