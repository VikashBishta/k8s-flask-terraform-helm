variable "app_name" {
  description = "Name of the APP"
  type        = string
  default     = "flask"

}

variable "replicas" {
  description = "Replicas"
  type        = number
  default     = 1

}

variable "image_url" {
  description = "Name of the IMAGE"
  type        = string
  default     = "flask-local:latest"

}

variable "container_port" {
  description = "Container Port"
  type        = number
  default     = 5000

}

variable "service_port" {
  description = "Service Port"
  type        = number
  default     = 80
}

variable "node_port" {
  description = "Node Port"
  type        = number
  default     = 30080 # привязывается к localhost:8080
}
