# Use the official Codespaces Ubuntu image as a base
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04


# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure Developer CLI (azd)
RUN curl -fsSL https://aka.ms/install-azd.sh | bash

# Install Bicep CLI
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 && chmod +x ./bicep && mv ./bicep /usr/local/bin/bicep

# [Optional] Install any other dependencies here
# RUN apt-get update && apt-get install -y <package-name>
RUN apt update
RUN apt -y install python3 
