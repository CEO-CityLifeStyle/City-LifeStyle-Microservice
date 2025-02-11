# Custom IAM Roles

# Frontend Service Role
resource "google_project_iam_custom_role" "frontend" {
  role_id     = "cityLifestyleFrontend"
  title       = "City Lifestyle Frontend Role"
  description = "Custom role for frontend service"
  permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.update",
    "cloudcdn.cacheinvalidations.create"
  ]
}

# Backend Service Role
resource "google_project_iam_custom_role" "backend" {
  role_id     = "cityLifestyleBackend"
  title       = "City Lifestyle Backend Role"
  description = "Custom role for backend service"
  permissions = [
    "cloudsql.instances.connect",
    "cloudsql.instances.get",
    "secretmanager.versions.access",
    "secretmanager.versions.get",
    "pubsub.topics.publish",
    "pubsub.subscriptions.consume",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create"
  ]
}

# CI/CD Role
resource "google_project_iam_custom_role" "cicd" {
  role_id     = "cityLifestyleCicd"
  title       = "City Lifestyle CI/CD Role"
  description = "Custom role for CI/CD pipelines"
  permissions = [
    "cloudbuild.builds.create",
    "cloudbuild.builds.get",
    "cloudbuild.builds.list",
    "cloudbuild.builds.update",
    "run.services.create",
    "run.services.get",
    "run.services.update",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.delete",
    "artifactregistry.repositories.uploadArtifacts",
    "secretmanager.versions.access"
  ]
}
