# Use the official Codespaces Ubuntu image as a base
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04


# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure Developer CLI (azd)
RUN curl -fsSL https://aka.ms/install-azd.sh | bash


# Install full Python 3.12 and pip, and ensure python3 and python are in PATH
RUN apt-get update \
	&& apt-get install -y python3.12 python3.12-venv python3.12-distutils python3-pip \
	&& ln -sf /usr/bin/python3.12 /usr/local/bin/python3 \
	&& ln -sf /usr/bin/python3.12 /usr/local/bin/python \
	&& python3 --version \
	&& pip3 --version \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*
