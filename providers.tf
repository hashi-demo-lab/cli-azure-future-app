terraform {
  cloud {
    organization = "hashi-demos-apj"

    workspaces {
      name = "cli-azure-future-app"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.39.0"
    }
  }
}
