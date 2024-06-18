
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "wid" {
  name     = "${var.prefix}-k8s-resources"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "wid" {
  name                      = "${var.prefix}-k8s"
  location                  = azurerm_resource_group.wid.location
  resource_group_name       = azurerm_resource_group.wid.name
  dns_prefix                = "${var.prefix}-wid"
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_user_assigned_identity" "azwid" {
  resource_group_name = azurerm_resource_group.wid.name
  location            = azurerm_resource_group.wid.location
  name                = "${var.prefix}-wid"
}

resource "azurerm_federated_identity_credential" "azwid" {
  name                = "${var.prefix}-wid-cred"
  resource_group_name = azurerm_resource_group.wid.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.wid.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.azwid.id
  subject             = "system:serviceaccount:default:workload-identity"
  depends_on = [
    azurerm_kubernetes_cluster.wid,
    azurerm_user_assigned_identity.azwid
  ]
}

resource "azurerm_cosmosdb_account" "wid" {
  name                = "spin-kv-cosmos-db"
  location            = azurerm_resource_group.wid.location
  resource_group_name = azurerm_resource_group.wid.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level       = "Strong"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }

  depends_on = [
    azurerm_resource_group.wid
  ]
}

resource "azurerm_cosmosdb_sql_database" "wid" {
  name                = "spin"
  resource_group_name = azurerm_resource_group.wid.name
  account_name        = azurerm_cosmosdb_account.wid.name

  depends_on = [
    azurerm_cosmosdb_account.wid
  ]
}

resource "azurerm_cosmosdb_sql_container" "wid" {
  name                  = "keys-and-values"
  resource_group_name   = azurerm_resource_group.wid.name
  account_name          = azurerm_cosmosdb_account.wid.name
  database_name         = azurerm_cosmosdb_sql_database.wid.name
  partition_key_path    = "/id"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }

  depends_on = [
    azurerm_cosmosdb_sql_database.wid
  ]
}

resource "azurerm_cosmosdb_sql_role_assignment" "wid" {
  resource_group_name = azurerm_resource_group.wid.name
  account_name        = azurerm_cosmosdb_account.wid.name
  role_definition_id  = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.wid.name}/providers/Microsoft.DocumentDB/databaseAccounts/${azurerm_cosmosdb_account.wid.name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002" # Data contributor
  principal_id        = azurerm_user_assigned_identity.azwid.principal_id
  scope               = azurerm_cosmosdb_account.wid.id

  depends_on = [
    azurerm_cosmosdb_account.wid,
    azurerm_user_assigned_identity.azwid
  ]
}

data "azurerm_subscription" "primary" {
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.wid.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_service_account" "wid" {
  metadata {
    name      = "workload-identity"
    namespace = "default"
    annotations = {
      "azure.workload.identity/client-id" = "${azurerm_user_assigned_identity.azwid.client_id}"
    }
  }
  depends_on = [
    azurerm_user_assigned_identity.azwid,
    azurerm_cosmosdb_sql_role_assignment.wid
  ]
}

resource "kubernetes_deployment" "spin-test" {
  metadata {
    name      = "spin-test"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "spin-test"
      }
    }

    template {
      metadata {
        labels = {
          app                           = "spin-test"
          "azure.workload.identity/use" = "true"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.wid.metadata.0.name
        container {
          image = var.app-image-ref
          name  = "spin-kv"
          env {
            name  = "RUST_LOG"
            value = "debug"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_account.wid
  ]
}

resource "kubernetes_service" "spin-test" {
  metadata {
    name      = "spin-test"
    namespace = "default"
  }

  spec {
    selector = {
      app = "spin-test"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }

  depends_on = [
    kubernetes_deployment.spin-test
  ]
}
