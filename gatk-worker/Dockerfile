FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y awscli && rm -rf /var/lib/apt/lists/*

COPY run_gatk.sh /usr/local/bin/run_gatk.sh
RUN chmod +x /usr/local/bin/run_gatk.sh