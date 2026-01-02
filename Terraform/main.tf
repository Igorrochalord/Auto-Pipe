terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
  
  # ATENÇÃO: Você deve criar este bucket manualmente na GCP antes de rodar
  backend "gcs" {
    bucket  = "meu-bucket-terraform-state" # Troque por um nome único seu
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# --- VARIÁVEIS (Vêm do GitHub Actions) ---

variable "project_id" {
  description = "O ID do projeto na GCP"
  type        = string
}

variable "docker_image" {
  description = "A URL completa da imagem Docker (ex: us-central1.../app:sha)"
  type        = string
}

# --- ARTIFACT REGISTRY (Onde guardamos o Docker) ---

# 1. Ativa a API necessária
resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# 2. Cria o Repositório
resource "google_artifact_registry_repository" "my_repo" {
  location      = "us-central1"
  repository_id = "pythonci"
  description   = "Repositorio Docker para a aplicacao Python"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry_api]
}

# --- CLOUD RUN (Onde roda a Aplicação) ---

resource "google_cloud_run_service" "app" {
  name     = "minha-app-hml"
  location = "us-central1"

  template {
    spec {
      containers {
        image = var.docker_image
        
        ports {
          container_port = 8080
        }
        
        # Opcional: Variáveis de ambiente para a sua aplicação
        env {
          name  = "AMBIENTE"
          value = "homologacao"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  
  # Garante que o registry exista antes de tentar subir a app
  depends_on = [google_artifact_registry_repository.my_repo]
}

# --- ACESSO PÚBLICO (IAM) ---

# Permite que qualquer pessoa na internet acesse a URL
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- OUTPUTS (Para você ver a URL no final) ---

output "url_da_aplicacao" {
  value = google_cloud_run_service.app.status[0].url
}