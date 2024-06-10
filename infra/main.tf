
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2"
    }
  }
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
  issuer              = azurerm_kubernetes_cluster.wid.oidc_issuer
  parent_id           = azurerm_user_assigned_identity.azwid.id
  subject             = "system:serviceaccount:default:workload-identity"
  depends_on = [
    azruerm_kubernetes_cluster.wid,
    azurerm_user_assigned_identity.azwid
  ]
}

resource "random_string" "rando" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_key_vault" "wid" {
  name                       = "${var.prefix}-wid"
  location                   = azurerm_resource_group.wid.location
  resource_group_name        = azurerm_resource_group.wid.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = false
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  network_acls {
    bypass         = "None"
    default_action = "Allow"
  }
}

resource "azurerm_key_vault_access_policy" "wid" {
  key_vault_id = azurerm_key_vault.wid.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.azwid.principal_id

  secret_permissions = [
    "get",
    "list"
  ]

  key_permissions = [
    "get",
    "list"
  ]

  certificate_permissions = [
    "get",
    "list"
  ]

  depends_on = [
    azurerm_key_vault.wid,
    azurerm_user_assigned_identity.azwid
  ]
}

resource "azure_key_vault_access_policy" "tf" {
  key_vault_id = azurerm_key_vault.wid.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "get",
    "list",
    "set",
    "delete",
    "purge",
    "recover",
    "backup",
    "restore"
  ]

  key_permissions = [
    "get",
    "list",
    "create",
    "import",
    "delete",
    "purge",
    "recover",
    "backup",
    "restore",
    "sign",
    "verify",
    "encrypt",
    "decrypt",
    "unwrapKey",
    "wrapKey"
  ]

  certificate_permissions = [
    "get",
    "list",
    "create",
    "import",
    "delete",
    "purge",
    "recover",
    "backup",
    "restore",
    "update",
    "managecontacts",
    "getissuers",
    "listissuers",
    "setissuers",
    "deleteissuers",
    "manageissuers",
    "recoverissuers",
    "backupissuers",
    "restoreissuers",
    "createissuers",
    "importissuers",
    "updateissuers",
    "getissuers",
    "listissuers",
    "setissuers",
    "deleteissuers",
    "manageissuers",
    "recoverissuers",
    "backupissuers",
    "restoreissuers",
    "createissuers",
    "importissuers",
    "updateissuers"
  ]

  depends_on = [
    azurerm_key_vault.wid,
  ]
}

resource "azurerm_key_vault_secret" "wid-secret" {
  name         = "wid-secret"
  value        = "super-secret"
  key_vault_id = azurerm_key_vault.wid.id
  depends_on = [
    azurerm_key_vault_access_policy.tf
  ]
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.wid.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.wid.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.wid.kube_config.0.cluster_ca_certificate)
  }
}

resource "kubernetes_service_account" "wid" {
  metadata {
    name      = "workload-identity"
    namespace = "default"
    annotations = {
      "azure.workload.identity" = "${azurerm_user_assigned_identity.azwid.client_id}"
    }
    labels = {
      "azure.workload.identity" = "use"
    }
  }
  depends_on = [
    azurerm_key_vault_access_policy.wid
  ]
}

resource "helm_release" "wid_chart" {
  name       = "wid-webhook"
  namespace  = "azure-workload-identity-system"
  chart      = "workload-identity-webhook"
  repository = "https://azure.github.io/azure-workload-identity/charts"

  force_update     = true
  create_namespace = true
  set {
    name  = "azureTenantID"
    value = data.azurerm_client_config.current.tenant_id
  }
}

resource "kubernetes_pod" "spin-test" {
  metadata {
    name      = "spin-test"
    namespace = "default"
    labels = {
      "azure-workload-identity/use" = "true"
    }
  }

  spec {
    service_account_name = kubernetes_service_account.wid.metadata.0.name
    container {
      image = var.app-image-ref
      name  = "oidc"
      env {
        name  = "KEYVAULT_URL"
        value = azurerm_key_vault.wid.vault_uri
      }
      env {
        name  = "SECRET_NAME"
        value = azurerm_key_vault_secret.wid-secret.name
    }
  }
}
