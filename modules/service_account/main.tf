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
  roles            = toset(var.service_account_roles)
  sensitive_roles  = ["roles/owner"] ### implementing this, to prevent IAM mayhem :)
  restricted_roles = setsubtract(local.roles, local.sensitive_roles)
}

resource "google_service_account" "account" {
  account_id   = var.account_id
  display_name = var.description
  description  = "Created by Terraform"
}

resource "google_project_iam_member" "service_account_roles" {
  project  = var.project_id
  for_each = local.restricted_roles
  role     = each.key
  member   = "serviceAccount:${google_service_account.service_account.email}"
}
