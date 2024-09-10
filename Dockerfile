# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /ansible

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ssh \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN pip install --no-cache-dir ansible

# Copy the ansible directory contents into the container
COPY ./ansible /ansible
COPY .ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

# Set environment variables
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

# Command to run when starting the container
CMD ["ansible-playbook", "--version"]