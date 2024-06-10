output "id" {
  value = azurerm_kubernetes_cluster.example.id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.example.kube_config_raw
}

output "client_key" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.client_key
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate
}

output "host" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.host
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.azwid.client_id
}

output "keyvault_uri" {
  value = azurerm_key_vault.wid.vault_uri
}
