# Start with AWS ECR Public Alpine Linux image
FROM public.ecr.aws/docker/library/alpine:latest

# Install system dependencies and Python
RUN apk update && \
    apk add --no-cache \
    python3 \
    py3-pip \
    python3-dev \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    curl \
    wget \
    git \
    bash \
    && rm -rf /var/cache/apk/*

# Create a non-root user
RUN adduser -D -u 1000 litellm

# Set working directory
WORKDIR /app

# Install litellm
RUN pip3 install --no-cache-dir litellm

# Install AWS SSM agent
RUN wget -O amazon-ssm-agent.tar.gz https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.tar.gz && \
    tar -xzf amazon-ssm-agent.tar.gz && \
    ./amazon-ssm-agent/install && \
    rm -rf amazon-ssm-agent.tar.gz amazon-ssm-agent

# Create SSM agent service script
RUN echo '#!/bin/sh' > /etc/init.d/amazon-ssm-agent && \
    echo 'case "$1" in' >> /etc/init.d/amazon-ssm-agent && \
    echo '  start)' >> /etc/init.d/amazon-ssm-agent && \
    echo '    /usr/local/bin/amazon-ssm-agent start' >> /etc/init.d/amazon-ssm-agent && \
    echo '    ;;' >> /etc/init.d/amazon-ssm-agent && \
    echo '  stop)' >> /etc/init.d/amazon-ssm-agent && \
    echo '    /usr/local/bin/amazon-ssm-agent stop' >> /etc/init.d/amazon-ssm-agent && \
    echo '    ;;' >> /etc/init.d/amazon-ssm-agent && \
    echo 'esac' >> /etc/init.d/amazon-ssm-agent && \
    chmod +x /etc/init.d/amazon-ssm-agent

# Switch to non-root user
USER litellm

# Expose the default litellm port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Default command to run litellm
CMD ["litellm", "--host", "0.0.0.0", "--port", "4000"]
