# Use a standard Ubuntu base image
FROM ubuntu:20.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install dependencies (including perl)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    default-jre \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Download and install FastQC
WORKDIR /opt
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip
RUN unzip fastqc_v0.11.9.zip
RUN chmod +x /opt/FastQC/fastqc

# Set the entrypoint for the container
ENTRYPOINT ["/opt/FastQC/fastqc"]