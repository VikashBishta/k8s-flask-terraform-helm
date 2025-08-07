# devops-lab-local
### English

## Description

A DevOps project for local deployment of a Flask microservice in Kubernetes (view) using Docker and Terraform. The project is built strictly according to the IAC principles — all infrastructure deployment is done through code.


## Stack

- **kind** — local Kubernetes cluster (runs in Docker)
- **Terraform** — cluster problem management via the "kubernetes" and "helm" providers.
- **Docker** — Flask application containerization
- **Flask** — simple web application

## Stage 1: launching a Kubernetes cluster type

### 1. Installation type

Download from the official website: https://kind.sigs.k8s.io/docs/user/quick-start/

### 2. Creating a cluster

``` bash
cluster creation type --config kind-cluster.yaml
```

The `kind-cluster.yaml` file specifies port forwarding:

```yaml
type: Cluster
APIVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control plane

additionalPortMappings:
- container port: 30080
host port: 8080
- container port: 30090
host port: 9090
```

### 3. Checking the cluster

``` bash
kubectl get nodes
kubectluster-info --context kind-kind
```
## Step 2: Flask app and Docker

### `app/` folder structure:

```
app/
├── main.py
├── requirements.txt
└── Dockerfile
```

### `main.py`

``` python
from flask import flask

app = Flask(__name__)

@app.route("/")
def home():
return "Hello, Vlad, from Flask app running!!!"

if __name__ == "__main__":
app.run(host="0.0.0.0", port=5000)
```

### `requirements.txt`

```
flask==3.1.1
```

### `Dockerfile`

```dockerfile
FROM python:3.9-slim
WORKING DIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "main.py"]
```

### Build Docker image

``` bash
docker build -t flask-local:latest ./app
```

### Upload image to cluster view

``` bash
upload view docker-image flask-local:latest
```

> This allows you to use a local image without publishing to Docker Hub or ECR.

---

## Terraform + Kubernetes Architecture

### Terraform Structure:

```
k8s/
├── provider.tf # connect to cluster
├── Deployment.tf # create Deployment for Flask
└── service.tf # create Service (NodePort) to access Flask
```

### provider.tf

```hcl
provider "kubernetes" {
config_path = "~/.kube/config"
}
```

Define Terraform as managers in an existing Kubernetes cluster ("view") using kubeconfig as "kubectl".

---

### deployment.tf

```hcl
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
name = var.app_name
image = var.image_url
image_pull_policy = "Never" # Important if you are running locally and the image is local

port {
container_port = var.container_port
}
}
}
}
}
}

```

Creates a pod via Deployment with label `app = flask` that runs `flask-local:latest` and exposes port 5000.

---

### service.tf

```hcl
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
port = var.service_port
target_port = var.container_port
node_port = var.node_port
}

}

}

```
### variables.tf

```hcl
variable "app_name" {
description = "Application name"
type = string
default = "flask"

}

variable "replicas" {
description = "Replicas"
type = number
default = 1

}

variable "image_url" {
description = "IMAGE name"
type = string
default = "flask-local:latest"

}

variable "container_port" {
description = "Container port"
type = number
default = 5000

}

variable "service_port" {
description = "Service port"
type = number
default = 80
}

variable "node_port" {
description = "Node port"
type = number
default = 30080 # binds to localhost:8080
}

```

Creates a NodePort type service. Opens port `localhost:8080` on the host, which is forwarded to the container with port 5000.

---

### Request flow

```
Browser (localhost:8080)

↓
NodePort service (30080 → 80)
↓
Selector: app = flask
↓
Pod: flask-app → Container: flask-local:latest (port 5000)
```

### Prometheus installation via Helm via Terraform
Prometheus is configured via Terraform, via the Helm provider. Example configuration (k8s/helm_prometheus.tf):
``` resource "helm_release" "prometheus" {
name = "prometheus"
repository = "https://prometheus-community.github.io/helm-charts"
chart = "prometheus"
namespace = "prometheus"
create_namespace = true

values = [
file("${path.module}/prometheus-values.yaml")
]
}
```
# prometheus-values.yaml
```
alertmanager:
  enabled: true

pushgateway:
  enabled: false

server:
  service:
  type: NodePort
  nodePort: 31000
```

Check:
kubectl get all -n prometheus

### Access Prometheus
To open Prometheus in a browser:
kubectl port-forward -n prometheus svc/prometheus-server 9090:80
http://localhost:9090

### Installing and running Grafana via Terraform + Helm
Create a Grafana Helm resource in grafana_helm.tf:
``` resource "helm_release" "grafana" { 
name = "grafana" 
repository = "https://grafana.github.io/helm-charts" 
chart = "grafana" 
namespace = "grafana" 

create_namespace = true 

values = [ 
file("${path.module}/grafana-values.yaml") 
]
}
```
# grafana-values.yaml
```
adminUser: admin
adminPassword: admin1976

service: 
  type: NodePort 
  port: 3000 
  nodePort: 31001

persistence: 
  enabled: true 
  size: 1Gi
```
# Service check
kubectl get svc -n grafana


# Launch Grafana
You need to forward the port
kubectl port-forward -n grafana svc/grafana 3000:3000
http://localhost:3000

The project is now complete. 07/08/2025


///////////////////////////////////////////////////////////////////////////////////////////////
### Russian
##  Описание

DevOps-проект для локального развёртывания микросервиса на Flask в Kubernetes (kind) с использованием Docker и Terraform. Проект построен строго по принципам IaC — всё инфраструктурное развёртывание автоматизировано через код.

##  Стек

- **kind** — локальный кластер Kubernetes (работает в Docker)
- **Terraform** — управление ресурсами в кластере через провайдер `kubernetes` и `helm`
- **Docker** — контейнеризация Flask-приложения
- **Flask** — простое веб-приложение


##  Этап 1: запуск Kubernetes-кластера kind

### 1. Установка kind

Скачать с официального сайта: https://kind.sigs.k8s.io/docs/user/quick-start/

### 2. Создание кластера

```bash
kind create cluster --config kind-cluster.yaml
```

Файл `kind-cluster.yaml` задаёт проброс портов:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 8080
      - containerPort: 30090
        hostPort: 9090
```

### 3. Проверка кластера

```bash
kubectl get nodes
kubectl cluster-info --context kind-kind
```


##  Этап 2: Flask-приложение и Docker

### Структура папки `app/`:

```
app/
├── main.py
├── requirements.txt
└── Dockerfile
```

### `main.py`

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello Vladi from Flask app running !!!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

### `requirements.txt`

```
flask==3.1.1
```

### `Dockerfile`

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "main.py"]
```

### Сборка Docker-образа

```bash
docker build -t flask-local:latest ./app
```

### Загрузка образа в кластер kind

```bash
kind load docker-image flask-local:latest
```

> Это позволяет использовать локальный образ в kind без публикации в Docker Hub или ECR.


##  Архитектура Terraform + Kubernetes

###  Структура Terraform:

```
k8s/
├── provider.tf        # подключение к кластеру
├── deployment.tf      # создание Deployment для Flask
└── service.tf         # создание Service (NodePort) для доступа к Flask
```

###  provider.tf

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

Позволяет Terraform управлять ресурсами в уже существующем Kubernetes-кластере (`kind`), используя kubeconfig как `kubectl`.


###  deployment.tf

```hcl
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
          image_pull_policy = "Never" # Важно если работаем локально и image локально

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}


```

Создаёт pod через Deployment с меткой `app = flask`, который запускает `flask-local:latest` и открывает порт 5000.


###  service.tf

```hcl
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


```
###  variables.tf

```hcl
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



```



Создаёт сервис типа NodePort. Открывает порт `localhost:8080` на хосте, который перенаправляется на контейнер с портом 5000.


###  Поток запроса

```
Браузер (localhost:8080)
     ↓
NodePort Service (30080 → 80)
     ↓
Selector: app = flask
     ↓
Pod: flask-app → Container: flask-local:latest (port 5000)
```

### Установка Prometheus через Helm через Terraform
Prometheus устанавливается через Terraform, используя Helm-провайдер. Пример конфигурации (k8s/helm_prometheus.tf):
``` resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "prometheus"

  create_namespace = true

  values = [
    file("${path.module}/prometheus-values.yaml")
  ]
} 
```
# prometheus-values.yaml
``` 
alertmanager:
  enabled: true

pushgateway:
  enabled: false

server:
  service:
    type: NodePort
    nodePort: 31000
```

Проверка:
kubectl get all -n prometheus

### Доступ к Prometheus
Чтобы открыть Prometheus в браузере:
kubectl port-forward -n prometheus svc/prometheus-server 9090:80
http://localhost:9090

### Установка и запуск Grafana через Terraform + Helm
Создайте Helm-ресурс Grafana в grafana_helm.tf:
``` resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "grafana"

  create_namespace = true

  values = [
    file("${path.module}/grafana-values.yaml")
  ]
}
```
# grafana-values.yaml
```
adminUser: admin
adminPassword: admin1976

service:
  type: NodePort
  port: 3000
  nodePort: 31001

persistence:
  enabled: true
  size: 1Gi
```
# Проверка сервиса
kubectl get svc -n grafana


# Запуск Grafana
Надо пробросить порт 
kubectl port-forward -n grafana svc/grafana 3000:3000
http://localhost:3000

На данный момент проект завершен. 07/08/2025