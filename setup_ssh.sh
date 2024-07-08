#!/bin/bash

# Define the key path
KEY_PATH="/home/ec2-user/environment/deployer-key"

# Generate the SSH key
ssh-keygen -t rsa -b 2048 -f ${KEY_PATH} -N ""

# Set the correct permissions
chmod 600 ${KEY_PATH}
chmod 644 ${KEY_PATH}.pub

# Output the public key content
cat ${KEY_PATH}.pub
