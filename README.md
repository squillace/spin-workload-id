# spin-workload-id

Azure Workload ID test

## To run the test

```bash
terraform apply -var 'location=westus3' -var 'prefix=test' -auto-approve
terraform output kube_config > .kconfig # this might need some trimming...
KUBECONFIG=.kconfig k describe pod spin-test | grep "SECRET_NAME:"
KUBECONFIG=.kconfig k logs spin-test
# I0614 00:48:17.478271 1 main.go:63] "successfully got secret" secret="super-secret"
```
