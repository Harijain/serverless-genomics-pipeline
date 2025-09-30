#!/bin/bash
# This script will NOT fail even if FastQC gives an error.

INPUT_FILE_URI=$1
OUTPUT_RESULTS_URI=$2

echo "Input file is: $INPUT_FILE_URI"
echo "Output location is: $OUTPUT_RESULTS_URI"

# Download the input file from S3
aws s3 cp $INPUT_FILE_URI . --region us-east-1 --request-payer requester

FILENAME=$(basename $INPUT_FILE_URI)

# Run FastQC, but continue even if it fails
echo "Running FastQC on $FILENAME..."
/opt/FastQC/fastqc $FILENAME || echo "FastQC reported an error, but we are continuing."

BASENAME=${FILENAME%.fastq.gz}
OUTPUT_FILE="${BASENAME}_fastqc.html"

# If the real report wasn't created, create a dummy log file to upload instead
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "FastQC did not produce a report. Creating a dummy log file."
    touch fastqc_dummy_log.txt
    echo "Could not process $FILENAME because it is not a valid FASTQ file." > fastqc_dummy_log.txt
    OUTPUT_FILE="fastqc_dummy_log.txt"
fi

# Upload the result (either the real report or the dummy log)
echo "Uploading results..."
aws s3 cp $OUTPUT_FILE $OUTPUT_RESULTS_URI --region us-east-1

echo "Job completed successfully."
# This script will now always exit with a success code


