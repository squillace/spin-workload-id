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

output "cosmosdb_account_name" {
  value = azurerm_cosmosdb_account.wid.name
}

output "cosmosdb_sql_database_name" {
  value = azurerm_cosmosdb_sql_database.wid.name
}

output "azurerm_cosmosdb_sql_container_name" {
  value = azurerm_cosmosdb_sql_container.wid.name
}

output "spin-kv-service-ip" {
  value = kubernetes_service.spin-test.status.0.load_balancer.0.ingress.0.ip
}
