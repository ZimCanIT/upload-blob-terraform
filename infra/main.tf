terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.35.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

#-------------------------------------------------------------

# provider configuration 
provider "azurerm" {
  features {
  }
}

#-------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "storage-acc-demo-rg"
  location = "West Europe"
}

#-------------------------------------------------------------

resource "random_integer" "sa_unique_no" {
  min = 10
  max = 500
}

#-------------------------------------------------------------

resource "azurerm_storage_account" "sa" {
  name                     = "zcitblobstoreacc${random_integer.sa_unique_no.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled       = true
    last_access_time_enabled = true
  }
}

#-------------------------------------------------------------

resource "azurerm_storage_container" "sa_container" {
  name                  = "blob-container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

#-------------------------------------------------------------

# upload blob in the same dir as terraform files
resource "azurerm_storage_blob" "blob1" {
  name                   = "t1.sh"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sa_container.name
  type                   = "Block"
  source                 = "t1.sh"
}

#-------------------------------------------------------------

# upload a blob in a subdirectory
resource "azurerm_storage_blob" "blob2" {
  name                   = "t2.sh"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sa_container.name
  type                   = "Block"
  source                 = "subdir-upload/t2.sh"
}

#-------------------------------------------------------------

# upload an entire subdirectory with nested directories to a container
resource "azurerm_storage_blob" "blob3" {
  for_each = fileset(path.module, "many-subdirs/**")

  name                   = each.key
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sa_container.name
  type                   = "Block"
  source                 = each.key
}

#-------------------------------------------------------------

# upload an entire subdirectory and nested directories to a new namespace in a storage container
resource "azurerm_storage_blob" "blob4" {
  for_each = fileset(path.module, "many-subdirs/**")

  name                   = "dir1/dir2/${each.key}"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sa_container.name
  type                   = "Block"
  source                 = each.key
}
#-------------------------------------------------------------