# modules/aci_import_helm_charts/main.tf

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id   = var.source_acr_client_id
  role_definition_name = "AcrPull"
  scope          = data.azurerm_container_registry.source_acr.id
}

data "azurerm_container_registry" "source_acr" {
  name                = var.source_acr_server
  resource_group_name = var.source_acr_resource_group
}

data "azurerm_container_registry" "acr_instance" {
  name                = var.acr_server
  resource_group_name = var.acr_resource_group
}

resource "null_resource" "import_charts" {
  triggers = {
    source_acr_id       = data.azurerm_container_registry.source_acr.id
    acr_instance_id     = data.azurerm_container_registry.acr_instance.id
    helm_release_config = jsonencode(var.charts)
  }

  provisioner "local-exec" {
    command = <<EOT
    for chart in \$(echo '${jsonencode(var.charts)}' | jq -c '.[]'); do
      chart_name=\$(echo \$chart | jq -r '.chart_name')
      chart_namespace=\$(echo \$chart | jq -r '.chart_namespace')
      chart_repository=\$(echo \$chart | jq -r '.chart_repository')
      chart_version=\$(echo \$chart | jq -r '.chart_version')
      values=\$(echo \$chart | jq -c '.values')
      sensitive_values=\$(echo \$chart | jq -c '.sensitive_values')

      helm repo add source_acr --username \$(az acr credential show --name ${data.azurerm_container_registry.source_acr.name} --resource-group ${data.azurerm_container_registry.source_acr.resource_group_name} | jq -r '.username') --password \$(az acr credential show --name ${data.azurerm_container_registry.source_acr.name} --resource-group ${data.azurerm_container_registry.source_acr.resource_group_name} | jq -r '.password') \$(az acr show --name ${data.azurerm_container_registry.source_acr.name} --resource-group ${data.azurerm_container_registry.source_acr.resource_group_name} | jq -r '.loginServer')

      helm repo update
      helm fetch source_acr/\$chart_name --version \$chart_version -d /tmp/
      helm upgrade --install \$chart_name /tmp/\$chart_name --namespace \$chart_namespace --values <(echo \$values) --set-string <(echo \$sensitive_values)
      helm repo remove source_acr
    done
    EOT
  }
}

output "imported_charts" {
  description = "Imported Helm charts from the reference ACR to the instance ACR and deployed on AKS."
  value       = null_resource.import_charts
}
