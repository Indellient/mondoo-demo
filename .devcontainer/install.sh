#!/bin/bash

ARCH=$(dpkg --print-architecture)

# Install OS dependencies
apt-get update
apt-get -y install --no-install-recommends gnupg gcc libc6-dev software-properties-common

if [[ "${ARCH}" == "arm64" ]]
then
    # Install AWS CLI
    curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o /tmp/awscliv2.zip
    unzip /tmp/awscliv2.zip
    ./aws/install

    # Install Terraform from binary
    curl https://releases.hashicorp.com/terraform/1.2.4/terraform_1.2.4_linux_arm64.zip -o terraform.zip
    unzip terraform.zip
    mv terraform /usr/local/bin/terraform
elif [[ "${ARCH}" == "amd64" ]]
then
    # Install AWS CLI
    curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
    unzip /tmp/awscliv2.zip
    ./aws/install

    # Install Terraform from package manager
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    apt-get update
    apt-get -y --no-install-recommends install terraform
    apt-get -y upgrade
else
    echo "Architecture is not supported - installation failed"
    exit 1
fi