#!/bin/bash
set -e

INPUT_FILE_URI=$1
OUTPUT_RESULTS_URI=$2

echo "Downloading input file: $INPUT_FILE_URI"

# Download the input file, adding the request-payer flag
aws s3 cp $INPUT_FILE_URI . --region us-east-1 --request-payer requester

FILENAME=$(basename $INPUT_FILE_URI)
echo "Running FastQC on $FILENAME"
/opt/FastQC/fastqc $FILENAME

BASENAME=${FILENAME%.fastq.gz}
echo "Uploading results to $OUTPUT_RESULTS_URI"
# Upload the HTML report to our S3 bucket
aws s3 cp ${BASENAME}_fastqc.html $OUTPUT_RESULTS_URI --region us-east-1

echo "Job completed."