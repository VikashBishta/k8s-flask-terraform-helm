resource "kubernetes_service" "flask" {
  metadata {
    name = "${var.app_name}-service"
  }
  spec {
    type = "NodePort"
    selector = {
      app = var.app_name
    }

    port {
      port        = var.service_port
      target_port = var.container_port
      node_port   = var.node_port
    }

  }

}
