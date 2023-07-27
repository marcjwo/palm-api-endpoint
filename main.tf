/**
* Copyright 2023 Google LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

locals {
  apis_to_activate = [
    "cloudfunctions",
    "run",
    "aiplatform",
    "artifactregistry"
  ]
}

resource "google_project_service" "apis_to_activate" {
  for_each           = toset(local.apis_to_activate)
  project            = var.project_id
  service            = "${each.key}.googleapis.com"
  disable_on_destroy = false
  # disable_dependent_services = true
  timeouts {
    create = "10m"
    update = "40m"
  }
}

module "cf_service_account" {
  source      = "./modules/service_account"
  project_id  = var.project_id
  account_id  = "cloud-function-serviceaccount"
  description = "Service account for cloud function"
  service_account_roles = [
    "roles/aiplatform.user",
    "roles/artifactregistry.reader"
  ]
  depends_on = [google_project_service.apis_to_activate]
}

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name     = "${random_id.default.hex}-gcf-source"
  location = var.region
  # uniform_bucket_level_access = true
  depends_on = [google_project_service.apis_to_activate]
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "functions/palm-chat/"
  depends_on  = [google_project_service.apis_to_activate]
}

resource "google_storage_bucket_object" "object" {
  name       = "function-source.zip"
  bucket     = google_storage_bucket.default.name
  source     = data.archive_file.default.output_path
  depends_on = [google_project_service.apis_to_activate]
}

resource "google_cloudfunctions2_function" "default" {
  name        = "palm-chat-endpoint"
  location    = var.region
  description = "Cloud function to facilitate palm chat api - to be used e.g. by a chatbot"

  build_config {
    runtime     = "python311"
    entry_point = "process_request" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      PROJECT_ID = var.project_id
      LOCATION   = "us-central1" ## this has to be us-central1 as of now, because PaLM is not available in another region yet.
    }
    service_account_email = module.cf_service_account.email
  }
  depends_on = [google_project_service.apis_to_activate]
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project    = google_cloudfunctions2_function.default.project
  location   = google_cloudfunctions2_function.default.location
  service    = google_cloudfunctions2_function.default.name
  role       = "roles/run.invoker"
  member     = "serviceAccount:${module.cf_service_account.email}"
  depends_on = [google_project_service.apis_to_activate]
}

output "function_endpoint" {
  value = google_cloudfunctions2_function.default.url
}
