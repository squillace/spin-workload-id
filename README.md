# Spin Workload Identity Demonstration

This project provides a demonstration of Spin's Key / Value store integration using Azure Workload Identity to access an Azure Cosmos DB instance. Not all this code is currently in the Spin repository, but it is intended to be merged in the future.

We will create a native image of Spin that includes the necessary changes to support Azure Workload Identity. We will then deploy a Kubernetes cluster in Azure, deploy the Spin image to the cluster, and demonstrate that Spin can access the Cosmos DB instance using the Azure Workload Identity credentials.

## To run this sample
To run this sample, you'll need the following prerequisites:
- [Terraform](https://www.terraform.io/downloads.html)
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Building the Spin image
This is assuming you have the Spin source code in a directory similar to the way spin is referenced below. This also includes some changes to the Spin runtime to discover Azure Workload Identity credentials via process environment variables.

```bash
docker buildx build --push --platform linux/amd64 . -t devigned/spin-kv-test:0.0.2 --build-context spin=../../fermyon/spin
```

### Deploying the infrastructure

```bash
terraform apply -var 'location=westus3' -var 'prefix=test' -auto-approve

```
