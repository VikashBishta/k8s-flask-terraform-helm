resource "kubernetes_deployment" "flask" {
  metadata {
    name = var.app_name
    labels = {
      app = var.app_name
    }
  }
  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }
      spec {
        container {
          name              = var.app_name
          image             = var.image_url
          image_pull_policy = "Never" # Важно если работаем локально и имеж локально

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}
