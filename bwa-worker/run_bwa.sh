#!/bin/bash
# A more robust script with explicit error handling

# Immediately exit if any command fails
set -e

INPUT_FILE_URI=$1
OUTPUT_RESULTS_URI=$2

echo "BWA Worker Started."
echo "Input received: $INPUT_FILE_URI"
echo "Output location: $OUTPUT_RESULTS_URI"

echo "Creating dummy output file..."
touch bwa_output.txt
echo "This is a dummy result from the BWA worker" > bwa_output.txt

echo "Attempting to upload dummy file to S3..."
aws s3 cp bwa_output.txt $OUTPUT_RESULTS_URI --region us-east-1

# Explicitly check the exit code of the last command
if [ $? -ne 0 ]; then
  echo "FATAL: S3 upload failed! Check IAM permissions."
  exit 1
fi

echo "BWA worker finished successfully."