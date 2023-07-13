terraform {
  required_version = "= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.57.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }

    statuscake = {
      source  = "StatusCakeDev/statuscake"
      version = "2.1.0"
    }
  }

  backend "azurerm" {
    container_name = "terraform-state"
  }
}
