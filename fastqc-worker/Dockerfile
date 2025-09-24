# Use a standard Ubuntu base image
FROM ubuntu:20.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    default-jre \
    perl \
    awscli \
    && rm -rf /var/lib/apt/lists/*

# Download and install FastQC
WORKDIR /opt
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip
RUN unzip fastqc_v0.11.9.zip
RUN chmod +x /opt/FastQC/fastqc
COPY run_fastqc.sh /usr/local/bin/run_fastqc.sh
RUN chmod +x /usr/local/bin/run_fastqc.sh