data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = "fqlcloudIST"
    workspaces = {
      name = var.globalwsname
    }
  }
}


variable "api_key" {
  type        = string
  description = "API Key"
}
variable "secretkey" {
  type        = string
  description = "Secret Key"
}
variable "globalwsname" {
  type        = string
  description = "TFC WS from where to get the params"
}


data "intersight_kubernetes_cluster" "iks" {
name = local.clustername
}

terraform {
  required_providers {
    intersight = {
      source = "ciscodevnet/intersight"
      version = "1.0.18"
    }
      helm = {
      source = "hashicorp/helm"
      version = "2.5.1"
    }
  }
}





provider "intersight" {
  apikey    = var.api_key
  secretkey = var.secretkey
  endpoint  = "https://intersight.com"
}

provider "helm" {
    kubernetes {
host = yamldecode(base64decode(data.intersight_kubernetes_cluster.iks.results[0].kube_config)).clusters[0].cluster.server
cluster_ca_certificate = base64decode(yamldecode(base64decode(data.intersight_kubernetes_cluster.iks.results[0].kube_config)).clusters[0].cluster.certificate-authority-data)
client_certificate = base64decode(yamldecode(base64decode(data.intersight_kubernetes_cluster.iks.results[0].kube_config)).users[0].user.client-certificate-data)
client_key = base64decode(yamldecode(base64decode(data.intersight_kubernetes_cluster.iks.results[0].kube_config)).users[0].user.client-key-data)
    } 
}

resource helm_release helloiksfrtfcb {
  name       = "iwocollector"
  namespace = "iwo-collector"
  chart = "https://github.com/abhcld/iks-ist-iwo-helmchart-demo/raw/main/iwo-k8s-collector-v1.0.1.tgz"
  set {
    name  = "iwoServerVersion"
    value = "8.5"
  }
  set {
    name  = "collectorImage.tag"
    value = "8.5.1"
  }
  set {
    name  = "targetName"
    value = "kubernetes-cluster01"
  }
}



locals {
    clustername = yamldecode(data.terraform_remote_state.global.outputs.clustername)
}
