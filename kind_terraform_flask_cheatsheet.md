
# 🧠 Kubernetes с kind + Terraform: Шпаргалка по Flask-приложению

## 🟢 1. Создать кластер kind

```bash
kind create cluster --name flask-cluster
```

> 💡 При необходимости можно создать кластер с пробросом порта через kind-config.yaml

---

## ⚙️ 2. Собрать Docker-образ

```bash
docker build -t flask-local:latest .
```

---

## 📦 3. Загрузить образ в кластер kind

```bash
kind load docker-image flask-local:latest --name flask-cluster
```

---

## 📁 4. Структура Terraform-проектa

```text
.
├── provider.tf           # Подключение к кластеру Kubernetes
├── deployment.tf         # Deployment (описание пода и контейнера)
├── service.tf            # NodePort-сервис
├── variables.tf          # Переменные (имя, порты, образ)
└── terraform.tfstate     # [автоматически создаётся]
```

---

## 🚀 5. Инициализация Terraform

```bash
terraform init
```

---

## 🔍 6. Проверка перед запуском

```bash
terraform plan
```

---

## 🚢 7. Применить инфраструктуру

```bash
terraform apply -auto-approve
```

---

## 🌐 8. Проверка

```bash
kubectl get pods
kubectl get svc
curl http://localhost:30080
```

> 💡 Порт 30080 должен быть указан в `NodePort` и проброшен при создании kind-кластера

---

## 🧼 9. Удаление

```bash
terraform destroy -auto-approve
kind delete cluster --name flask-cluster
```

---

## ❗️ Полезно помнить:

- `image_pull_policy = "Never"` — обязательно, чтобы использовать локальный образ
- `kind load docker-image` нужно делать после **каждой** сборки `docker build`
- kind не сохраняет образы между рестартами — загружай каждый раз
- `terraform` работает через `provider "kubernetes"` и `kubeconfig`
