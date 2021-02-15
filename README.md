# Example OSB CI/CD Pipeline
This is an example CI/CD Pipeline to be used in combination with the [UniPipe Service Broker](https://github.com/meshcloud/unipipe-service-broker). It shows
how the communication is done via a Git repo between the API and the pipeline.

The pipeline is divided up into 3 different jobs:

- Prepare: It prepares the instance. Terraform deployment and AWS EC2 type provisioning are extracted from the instance.yml and the environment and written to an instance.tfvars file.
- Deploy: The provisioning of the service instance is done in this job. It uses the prepared SSH key and instance.tfvars file to actually create the service instance via Terraform and configure it via Ansible. The instances are running in OpenStack.
- Bindings: Bindings are created in a separate step. Creates access credentials that are written back to the GIT repo. For production use, credentials should not be written to GIT, but something like Vault should be used for that. But for demo purposes, this approach is sufficient.

## Instances Git repository
Via the instances repository the communication with the UniPipe Service Broker is done. You can find details about the files to be exchanged in the [UniPipe Service Broker Readme](https://github.com/meshcloud/unipipe-service-broker).

## Configure pipeline
To configure the pipeline you have to create secrets in the github repository to access the credentials to deploy the instance in aws and github access token to clone the instance repo and commit the changes to it.

Secrets used in this example repo:

Create a programmatic user in aws who has access rights to create/delete ec2 instance

AWS_ACCESS_KEY: AKIAIOSFODNN7EXAMPLE

AWS_SECRET_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

Git credentials to access the github repository

GIT_USERNAME: git username

GIT_PAT: git personal access token which have access rights to repo and workflow 

GIT_REMOTE: url to instance repository

MEDIUM_FLAVOR: t2.micro 

SMALL_FLAVOR: t2.nano
