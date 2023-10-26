module "chart" {
  source                      = "./modules/aci_import_helm_charts"
  acr_server                  = "instance.azurecr.io"
  acr_resource_group           = "instance-acr-rg"
  source_acr_client_id        = "1b2f651e-b99c-4720-9ff1-ede324b8ae30"
  source_acr_server           = "reference.azurecr.io"
  source_acr_resource_group   = "reference-acr-rg"
  kubeconfig_path             = var.kubeconfig_path

  charts = [
    {
      chart_name      = "chartetst"
      chart_namespace = "testing_charts"
      chart_repository = "tester_charting"
      chart_version   = "1.0"
      values = [
        {
          name  = "<name>"
          value = "<value>"
        },
        {
          name  = "<name>"
          value = "<value>"
        }
      ]
      sensitive_values = [
        {
          name  = "<name>"
          value = "<value>"
        },
        {
          name  = "<name>"
          value = "<value>"
        }
      ]
    }
  ]
}
