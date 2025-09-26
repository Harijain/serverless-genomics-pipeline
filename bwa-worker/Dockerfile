FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Update and install BWA and the AWS CLI
RUN apt-get update && apt-get install -y \
    bwa \
    awscli \
    && rm -rf /var/lib/apt/lists/*

COPY run_bwa.sh /usr/local/bin/run_bwa.sh
RUN chmod +x /usr/local/bin/run_bwa.sh