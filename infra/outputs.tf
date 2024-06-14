output "id" {
  value = azurerm_kubernetes_cluster.wid.id
}

output "tenant_id" {
  value     = data.azurerm_client_config.current.tenant_id
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.wid.kube_config_raw
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.wid.kube_config.0.client_key
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.wid.kube_config.0.client_certificate
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.wid.kube_config.0.cluster_ca_certificate
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.wid.kube_config.0.host
  sensitive = true
}

output "workload_identity_client_id" {
  value     = azurerm_user_assigned_identity.azwid.client_id
  sensitive = true
}

output "keyvault_uri" {
  value     = azurerm_key_vault.wid.vault_uri
  sensitive = true
}
