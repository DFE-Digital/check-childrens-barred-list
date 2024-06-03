terraform {
  required_version = "= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.104.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }

    statuscake = {
      source  = "StatusCakeDev/statuscake"
      version = "2.2.0"
    }
  }

  backend "azurerm" {
    container_name = "terraform-state"
  }
}
