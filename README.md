# GitHub Windows IaC

Infrastructure as Code (IaC) modules and automation for use with the Lockdown Enterprise (LE) Windows-based pipelines. This central repository supports Windows benchmarking, deployment automation, and security hardening for CI workflows using Terraform (OpenTofu) and Ansible.

---

## 📚 Table of Contents

1. [📦 Features](#1-️features)
2. [🔐 Required Secrets](#2-️required-secrets)
3. [📘 Repository Variables (Required)](#3-️repository-variables-required)
4. [🏗️ IaC Modules](#4-️iac-modules)
5. [🧪 Pipeline Validation Workflows](#5-️pipeline-validation-workflows)
6. [🧪 Pipeline Validation Workflows](#6-️pipeline-validation-workflows)
   - [6.1 🧼 Standard Benchmark Validation](#61-️standard-benchmark-validation)
     - [6.1.1 Trigger Files](#611-trigger-files)
   - [6.2 🏛 GPO Benchmark Validation](#62-️gpo-benchmark-validation)
     - [6.2.1 Trigger Files](#621-trigger-files)
   - [6.3 📈 Workflow Matrix](#63-️workflow-matrix)
     - [6.3.1 🧪 Example Workflow Usage](#631-️example-workflow-usage)
       - [6.3.1.1 🔧 main_pipeline_validation.yml](#6311--main_pipeline_validationyml)
       - [6.3.1.2 🏛 main_pipeline_validation_gpo.yml](#6312--main_pipeline_validation_gpoyml)
       - [6.3.1.3 🧪 devel_pipeline_validation.yml](#6313--devel_pipeline_validationyml)
       - [6.3.1.4 🏛 devel_pipeline_validation_gpo.yml](#6314--devel_pipeline_validation_gpoyml)
7. [🖥️ Run Locally (Test Terraform + Ansible)](#7-️run-locally-test-terraform--ansible)
8. [🔁 Reusable GitHub Actions Workflows](#8-️reusable-github-actions-workflows)
   - [8.1 📂 Available Shared Workflows](#81-available-shared-workflows)
   - [8.2 🧩 Usage in Benchmark Repositories](#82-usage-in-benchmark-repositories)
   - [8.3 🔒 Badge Secret Note](#83-badge-secret-note)
   - [8.4 🧭 Workflow Flow](#84-workflow-flow)
9. [🏷️ Badge Types and Their Sources](#9-️badge-types-and-their-sources)
   - [9.1 🧷 Recommended Badge Format](#91-recommended-badge-format)
   - [9.2 🧰 Badge Integration Guidance](#92-badge-integration-guidance)
   - [9.3 ✅ Recommended Placement in README.md](#93-recommended-placement-in-readmemd)
10. [📈 Benchmark Tracker & Teams/Discord Notifications](#10-️benchmark-tracker--teamsdiscord-notifications)
    - [10.1 🧩 Workflow Files](#101-️workflow-files)
    - [10.2 🔐 Required Secrets](#102-️required-secrets)
    - [10.3 📝 Setup Checklist](#103-setup-checklist)
    - [10.4 📘 Additional Notes](#104-additional-notes)
11. [🔍 Benchmark Tracker Workflow Details](#11-️benchmark-tracker-workflow-details)
    - [11.1 📜 benchmark-tracker Workflow](#111--benchmark-tracker-workflow)
    - [11.2 ⏱ monitor-90day-promotions Workflow](#112--monitor-90day-promotions-workflow)
    - [11.3 🛠️ Code Highlights](#113-️code-highlights)
    - [11.4 🛠️ How the Tracker System Works](#114-️how-the-tracker-system-works)
12. [💬 Notification Examples](#12-️notification-examples)
13. [🐧 Linux Benchmark Badge Support](#13-️linux-benchmark-badge-support)

---

## 1. 📦 Features

- Centralized IaC logic for all Windows benchmark pipelines (CIS/STIG)
- Dynamic provisioning of Hyper-V Windows runners using OpenTofu
- Self-hosted runner workflows with automatic Terraform + Ansible flow
- GPO testing support via alternate variable files (e.g., `WIN2022GPO.tfvars`)
- Discord onboarding notifications for first-time contributors
- Shared GitHub Actions workflows for badge export and testing
- Support for local testing of IaC outside GitHub Actions

---

## 2. 🔐 Required Secrets (Required)

These secrets must be configured under `Settings → Secrets → Actions` (repo or org level).
The Private repos will need to be configured in the individual repos because the org secrets
do not funtion in private on our current plan.:

| Secret Name              | Description                                       |
|--------------------------|---------------------------------------------------|
| `AZURE_AD_CLIENT_ID`     | Azure AD app registration client ID              |
| `AZURE_AD_CLIENT_SECRET` | Azure AD app secret                              |
| `AZURE_AD_TENANT_ID`     | Azure AD tenant ID                               |
| `AZURE_SUBSCRIPTION_ID`  | Azure subscription ID                            |
| `WIN_USERNAME`           | Admin username for the Windows VM                |
| `WIN_PASSWORD`           | Admin password for the Windows VM                |

---

## 3. 📘 Repository Variables (Required)

These must be added under `Settings → Actions → Variables` in benchmark repos (e.g., `Windows-2022-CIS`):

| Variable Name              | Description                                                      | Example              |
|----------------------------|------------------------------------------------------------------|----------------------|
| `ANSIBLE_RUNNER_VERSION`   | Version of Ansible used by the CI runner                         | `2.16.2`             |
| `BENCHMARK_TYPE`           | Benchmark under test (`CIS`, `STIG`, etc.)                       | `CIS`                |
| `ENABLE_DEBUG`             | Enable debug output and disable auto-destroy (`true/false`)      | `false`              |
| `IAC_BRANCH`               | GitHub branch to load IaC modules from                           | `main` or `devel`    |
| `OSVAR`                    | OS tfvars file base name (e.g., `WIN2025`)                       | `WIN2025`            |
| `GPO_OSVAR`                | OS tfvars for GPO variant (e.g., `WIN2025GPO`)                   | `WIN2025GPO`         |

---

## 4. 🏗️ IaC Modules

This repo uses [OpenTofu](https://opentofu.org/) to provision Windows test runners locally or inside GitHub Actions for compliance validation.

### Terraform Files

| File                | Description                                                               |
|---------------------|---------------------------------------------------------------------------|
| `main.tf`           | Creates Hyper-V-based Windows VMs with required networking and provisioning logic |
| `vars.tf`           | Defines all input variables used by main Terraform plan                    |
| `WIN2022.tfvars`    | Variable file for standard Windows Server 2022 runner setup                |
| `WIN2022GPO.tfvars` | GPO testing variant for Windows Server 2022                               |

---

## 5. 🧪 Pipeline Validation Workflows

This repository supports automated validation pipelines that run on every push to `main` or `devel` branches of Windows benchmark repositories. These workflows are split by purpose:

- Standard validation (`main_pipeline_validation.yml`, `devel_pipeline_validation.yml`)
- Group Policy (GPO) validation (`main_pipeline_validation_gpo.yml`, `devel_pipeline_validation_gpo.yml`)

---

## 6. 🧪 Pipeline Validation Workflows

### 6.1 🧼 Standard Benchmark Validation

Provision → Apply → Validate → Destroy

These workflows provision a fresh Windows environment, apply the benchmark using Ansible, and validate compliance.

#### 6.1.1 Trigger Files:
- `.github/workflows/main_pipeline_validation.yml`
- `.github/workflows/devel_pipeline_validation.yml`

```mermaid
graph TD;
  A[Push to Main or Devel] --> B[Trigger Pipeline Workflow]
  B --> C[Load IaC repo]
  C --> D[Import Variables and Secrets]
  D --> E[Setup Environment: Terraform + Ansible]
  E --> F[Run terraform init]
  F --> G[Run terraform validate]
  G --> H[Run terraform apply → provision Windows host]
  H --> I[Wait 60s if ENABLE_DEBUG is set]
  I --> J[Run ansible-playbook → apply hardening]
  J --> K[Validate results]
  K --> L[Run terraform destroy to clean up]
```

---

### 6.2 🏛 GPO Benchmark Validation

These workflows use a GPO-specific configuration to validate settings enforced through Group Policy Objects.

#### 6.2.1 Trigger Files:
- `.github/workflows/main_pipeline_validation_gpo.yml`
- `.github/workflows/devel_pipeline_validation_gpo.yml`

```mermaid
graph TD;
  A[Push to Main or Devel GPO] --> B[Trigger GPO Pipeline Workflow]
  B --> C[Load IaC repo for GPO testing]
  C --> D[Import GPO-specific tfvars e.g., WIN2022GPO]
  D --> E[Setup Terraform + Ansible for GPO run]
  E --> F[Run terraform init]
  F --> G[Run terraform validate]
  G --> H[terraform apply to launch GPO test VM]
  H --> I[Inject Group Policy settings via Ansible]
  I --> J[Audit or validate policy impact]
  J --> K[Run terraform destroy to clean up]
```

Each workflow is fully integrated with badge export automation and can be extended with extra validation stages (e.g., log parsing, custom output diffing) as needed.

### 6.3 📈 Workflow Matrix

| Workflow Filename                    | Description                                     | Trigger Branches         | OSVAR Source     |
|-------------------------------------|-------------------------------------------------|--------------------------|------------------|
| `main_pipeline_validation.yml`      | Validates Ansible remediation on main release   | `main`, `latest`         | `${OSVAR}`       |
| `main_pipeline_validation_gpo.yml`  | Validates GPO settings using Ansible            | `main`, `latest`         | `${GPO_OSVAR}`   |
| `devel_pipeline_validation.yml`     | Validates draft PRs and benchmark experiments   | `devel`, `benchmark_*`   | `${OSVAR}`       |
| `devel_pipeline_validation_gpo.yml` | GPO validation for draft/benchmark branches     | `devel`, `benchmark_*`   | `${GPO_OSVAR}`   |

---

## 6.3.1 🧪 Example Workflow Usage

These workflows are automatically triggered, but you can simulate them via PRs.

### 6.3.1.1 🔧 main_pipeline_validation.yml
```bash
# Triggers on PR to main/latest
# Uses: ${OSVAR}.tfvars
```

### 6.3.1.2 🏛 main_pipeline_validation_gpo.yml
```bash
# Triggers on PR to main/latest for GPO testing
# Uses: ${GPO_OSVAR}.tfvars
```

### 6.3.1.3 🧪 devel_pipeline_validation.yml
```bash
# Triggers on PR to devel or any 'benchmark_*' branch
# Uses: ${OSVAR}.tfvars
```

### 6.3.1.4🏛 devel_pipeline_validation_gpo.yml
```bash
# Triggers on PR to devel or 'benchmark_*' for GPO enforcement
# Uses: ${GPO_OSVAR}.tfvars
```

---

## 7. 🖥️ Run Locally (Test Terraform + Ansible)

```bash
export BENCHMARK_TYPE="CIS"
export OSVAR="WIN2022"
export TF_VAR_repository="${OSVAR}-${BENCHMARK_TYPE}"
export TF_VAR_BENCHMARK_TYPE="${BENCHMARK_TYPE}"

terraform init
terraform validate
terraform apply -var-file="WIN2022.tfvars" --auto-approve
terraform destroy -var-file="WIN2022.tfvars" --auto-approve
```

---

## 8. 🔁 Reusable GitHub Actions Workflows

This repository (`github_windows_IaC`) maintains **shared GitHub Actions workflows** that are reused by Windows benchmark repos to manage badge exports and automation logic.

### 8.1 📂 Available Shared Workflows

| Workflow Filename                | Purpose                                       |
|----------------------------------|-----------------------------------------------|
| `.github/workflows/export_badges_private.yml` | Used in **private** repos for badge JSON export |
| `.github/workflows/export_badges_public.yml`  | Used in **public** repos for shields.io badge endpoints |

### 8.2 🧩 Usage in Benchmark Repositories

Benchmark repos include a wrapper workflow like:

```yaml
# .github/workflows/export_badges_private.yml
name: Export Badges to Private Repo
on:
  push:
    branches: [ latest ]
jobs:
  export-badges:
    uses: ansible-lockdown/github_windows_IaC/.github/workflows/export_badges_private.yml@main
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      BADGE_PUSH_TOKEN: ${{ secrets.BADGE_PUSH_TOKEN }}
```

> The reusable logic lives in the `github_windows_IaC` repo. This makes badge generation portable and consistent.

---

### 8.3 🔒 Badge Secret Note

| Secret Name        | Where Needed   | Notes                                                              |
|--------------------|----------------|---------------------------------------------------------------------|
| `BADGE_PUSH_TOKEN` | 🔒 Private Repos | Must be set **manually** even if it exists at the org level         |
| `GH_TOKEN`         | All repos       | Provided automatically by GitHub Actions                           |

---

### 8.4 🧭 Workflow Flow

```mermaid
graph TD;
  A[Push to latest or main branch] --> B[Triggers local wrapper workflow]
  B --> C[Calls reusable IaC workflow using 'uses']
  C --> D[Generates JSON badge data]
  D --> E[Pushes to badge cache or GitHub Pages]
  E --> F[Badge rendered via shields.io or embedded in README]
```

---

## 9. 🏷️ Badge Types and Their Sources

This repository supports a wide variety of badges across **public** and **private** benchmark repositories. These badges serve different purposes and come from different systems.

| Badge Type                    | Source System                  | Example Badge | Notes |
|------------------------------|--------------------------------|----------------|-------|
| **GitHub Stats (Stars/Forks)** | GitHub (static links)         | ![Stars](https://img.shields.io/github/stars/ansible-lockdown/Windows-2019-CIS?style=social) | Hardcoded to specific repo/org |
| **Twitter & Discord**        | External services              | ![Discord](https://img.shields.io/discord/925818806838919229?logo=discord) | Hardcoded link or ID |
| **License Badge**            | GitHub                        | ![License](https://img.shields.io/github/license/ansible-lockdown/Windows-2019-CIS?label=License) | Hardcoded, dynamic on GitHub |
| **Lint Tools (yamllint, ansible-lint)** | Hardcoded manually            | ![YamlLint](https://img.shields.io/badge/yamllint-Present-brightgreen?style=flat&logo=yaml) | Always present (not dynamic) |
| **GitHub Actions Status**    | GitHub Workflow Badge URLs     | [![Main Status](https://github.com/ansible-lockdown/Windows-2019-CIS/actions/workflows/main_pipeline_validation.yml/badge.svg)](https://github.com/ansible-lockdown/Windows-2019-CIS/actions/workflows/main_pipeline_validation.yml) | Dynamic, GitHub-managed |
| **Commits, Issues, PRs**     | GitHub                         | ![Open Issues](https://img.shields.io/github/issues-raw/ansible-lockdown/Windows-2019-CIS) | Dynamic, GitHub-managed |
| **Pre-Commit CI**            | IaC Badge JSON (hosted)        | [![Pre-Commit.ci](https://img.shields.io/endpoint?url=https://ansible-lockdown.github.io/github_windows_IaC/badges/Windows-2019-CIS/pre-commit-ci.json)](https://results.pre-commit.ci/latest/github/ansible-lockdown/Windows-2019-CIS/devel) | 🔄 Updated via IaC workflow |
| **Benchmark Version Badges** | IaC Badge JSON                 | ![Benchmark](https://img.shields.io/endpoint?url=https://ansible-lockdown.github.io/github_windows_IaC/badges/Windows-2019-CIS/benchmark-version-main.json) | 🔄 Dynamic IaC badge |
| **Private Repo Badges**      | IaC Badge JSON                 | ![Private Benchmark](https://img.shields.io/endpoint?url=https://ansible-lockdown.github.io/github_windows_IaC/badges/Private-Windows-2019-CIS/benchmark-version.json) | 🔐 Internal subscribers only |
| **Release Branch**           | Hardcoded or IaC badge         | ![Release Branch](https://img.shields.io/badge/Release%20Branch-Main-brightgreen) / IaC endpoint | Sometimes manually added |

---

## 9.1 🧷 Recommended Badge Format

```markdown
[![Pre-Commit](https://img.shields.io/endpoint?url=https://ansible-lockdown.github.io/github_windows_IaC/badges/Windows-2022-CIS/pre-commit-ci.json)](https://results.pre-commit.ci/latest/github/ansible-lockdown/Windows-2022-CIS/devel)
```
---

## 9.2 🧰 Badge Integration Guidance

- **Dynamic badges** use `.json` files hosted in the `github_windows_IaC` `badges/` folder.
- They are updated using the [`export_badges_public.yml`](https://github.com/ansible-lockdown/github_windows_IaC/blob/main/.github/workflows/export_badges_public.yml) and `export_badges_private.yml` workflows.
- Public repos use pre-built shields.io URLs.
- Private repos consume the same badge format but must manually set the `BADGE_PUSH_TOKEN`.

---

## 9.3 ✅ Recommended Placement in README.md

You can structure your badge sections like this:

```markdown
## Public Repository 📣

![Org Stars](...)
![Repo Stars](...)
![License](...)
[![Pre-Commit](...)](...)
![Benchmark Version](...)
[![Main Pipeline](...)](...)
...

## Subscriber Release Information 🔐

![Private Benchmark Version](...)
[![Private GPO Pipeline](...)](...)
...
```

---

## 10. 📈 Benchmark Tracker & Teams/Discord Notifications

The `github_windows_IaC` repository contains a shared workflow system that automates **benchmark version tracking** across private repositories. Once a benchmark reaches 90 days in a private repo, it is eligible for **auto-promotion** to its corresponding public repository. Notifications are sent via **Microsoft Teams** and **Discord**.

---

### 10.1 🧩 Workflow Files

| Workflow File                  | Description                                                                 |
|-------------------------------|-----------------------------------------------------------------------------|
| `benchmark_track.yml`         | Called by private repos to initiate tracking. Determines if a benchmark version is missing from the public repo, and opens a 90-day issue if so. Sends Teams and Discord notifications. |
| `benchmark_promote.yml`       | Called daily from a central repo. Monitors all tracking issues. If 90+ days old, closes issues (if already promoted) or auto-creates PRs. Sends milestone reminders and promotion alerts. |

---

### 10.2 🔐 Required Secrets

These secrets **must** be configured in the GitHub repositories involved:

| Secret Name            | Scope              | Purpose                                                                 |
|------------------------|---------------------|-------------------------------------------------------------------------|
| `GH_TOKEN`             | All repos           | Required for GitHub CLI operations (issues, PRs, comments, etc.)        |
| `TEAMS_WEBHOOK_URL`    | All repos           | Used to send Adaptive Card notifications to Microsoft Teams             |
| `DISCORD_WEBHOOK_URL`  | All repos           | Sends milestone, promotion, and closure alerts to Discord channels      |
| `BADGE_PUSH_TOKEN`     | All repos           | Grants write access to push badge files to `github_windows_IaC`        |

> Add these under: `Settings → Secrets → Actions` for each participating repository.

---

# 📝 10.3 Setup Checklist

Set the required secrets in each **Private** repo:

- `GH_TOKEN`
- `TEAMS_WEBHOOK_URL`
- `DISCORD_WEBHOOK_URL`
- `BADGE_PUSH_TOKEN`

**Private Repo:**
- Call `benchmark_track.yml` from PR merges or scheduled runs.

**IaC Repo:**
- Schedule `benchmark_promote.yml` to run daily.

**Public Repo:**
- Ensure `devel` branch and `README.md` exist to validate versions.

**Teams/Discord Webhooks:**
- Ensure your automation supports HTTP POST with full JSON payloads.

---

## 📘 10.4 Additional Notes

- Benchmarks must follow naming conventions (`Private-Windows-*` → `Windows-*`).
- `README.md` format must include a recognizable version string (e.g., `vX.Y.Z` or `Version X, Rel Y`).
- All workflows are modular and intended to be reused across repos.
- Discord support is now included in all milestones and promotion actions.

> ✅ This setup ensures full traceability and timely promotion of compliance benchmarks while keeping all stakeholders informed.

---

## 11 🔍 Benchmark Tracker Workflow Details

### 11.1 📜 `benchmark-tracker` Workflow

Triggered when a pull request from a branch matching `benchmark_*` is merged into the `latest` branch of a **Private** repo.

#### 🔄 What it does:

1. **Extract version from PR branch name**
   Example: `benchmark_v2.0.0` becomes `v2.0.0`
2. **Create a GitHub issue** in the same repo with a 90-day countdown
3. **Assign labels**, version tags, and metadata to the issue
4. **Post a confirmation comment** in the PR for traceability

This tracks the need to promote this version publicly after 90 days.

---

### 11.2 ⏱ `monitor-90day-promotions` Workflow

Runs daily from the **IaC repo**. Monitors issues created by the tracker workflow.

#### 🔄 What it does:

1. **Scan all private repos** for open issues labeled as benchmark trackers
2. **Parse the issue body** to extract the version, repo name, and date created
3. **Calculate the age of each issue**
4. If the issue is **older than 90 days**:
   - Clones the corresponding **public repo**
   - Creates a PR to add the benchmark version to the `main` branch
   - Uses `gh pr create` and `gh pr merge` to automate promotion
   - Pushes new badge files to `github_windows_IaC`
   - Sends a **Teams notification** with summary info
   - Closes the original issue with a comment

> If the issue is **not** yet 90 days old, it is skipped and checked again on the next scheduled run.

---

### 11.3 🛠️ Code Highlights

Each step is modularized inside the workflow YAML:

- `benchmark-tracker.yml`
  - `- name: Detect PR branch and extract version`
  - `- name: Create 90-day tracking issue`
  - `- name: Label and annotate PR`
- `monitor-90day-promotions.yml`
  - `- name: Search for benchmark tracker issues`
  - `- name: Compare age against 90-day threshold`
  - `- name: Promote version if qualified`
  - `- name: Send Teams notification via webhook`
  - `- name: Update badge JSON in IaC`

---

### 11.4 🛠️ How the Tracker System Works

```mermaid
graph TD;
  A[Private Repo Calls benchmark_track.yml] --> B{Is Public Repo Missing Version?}
  B -- No --> C[No Action Needed]
  B -- Yes --> D[Open 90-Day Tracking Issue]
  D --> E[Send Tracking Start Notifications]
  E --> F[benchmark_promote.yml Runs Daily]
  F --> G{Is Issue 90+ Days Old?}
  G -- No --> H[Send Milestone Reminders (30/60/90 Days)]
  G -- Yes --> I{Already Promoted?}
  I -- Yes --> J[Close Issue, Send Notifications]
  I -- No --> K[Create PR to Public Repo]
  K --> L[Send PR Notifications to Teams & Discord]
```

---

### 12. 💬 Notification Examples

The system supports **Teams** and **Discord** alerts for all key events during benchmark tracking and promotion. These include:

- ✅ Tracking Started
- 🚨 Public Repo Missing
- ⏰ Milestone Reminders (30, 60, 90 days)
- ⚠️ Overdue Warnings
- ✅ Already Promoted Notices
- ❌ Promotion Blocked Alerts
- 🚨 Auto-Promotion PR Created

Each message is customized for Teams and Discord formatting, with links to issues and PRs where applicable.

---

#### ✅ Tracking Started — Teams
```markdown
🚀 Tracking Initiated - v2.0.0
🔒 Subscriber Repo: ansible-lockdown/Private-Windows-2022-CIS
📦 Subscriber Version: v2.0.0
🌐 Community Target: ansible-lockdown/Windows-2022-CIS
📦 Community Version: v1.9.0
⏳ Subscriber Review Ends: Approx: 2025-09-07
🗓️ Auto-Promotion Date To Community: Approx: 2025-09-12
📅 Promotion In: 90 days
```

#### 🚨 Public Repo Missing — Teams
```markdown
🚨 Tracking Started — But There's A Problem 🚨
Benchmark version 'v2.0.0' from **Private-Windows-2022-CIS** has entered the 90-day window.
⚠️ However, the public repo **Windows-2022-CIS** is missing or incomplete.
📢 Please create and prepare the community repo.
```

#### ✅ Tracking Started — Discord
```markdown
🚀 Benchmark Release To Community Tracking Started
🔒 Subscriber Repo: ansible-lockdown/Private-Windows-2022-CIS
📦 Subscriber Version: v2.0.0
🌐 Community Repo: ansible-lockdown/Windows-2022-CIS
📦 Community Version: v1.9.0
⏳ Review Ends: 2025-09-07
🗓️ Auto-Promotion Date: 2025-09-12
```

#### ⏰ 30/60/90 Day Reminder — Discord
```markdown
⏰ Benchmark Promotion Milestone
📢 60-Day Reminder: Benchmark `v2.0.0` is scheduled for promotion in 30 days.
⚠️ If not promoted manually, auto-promotion occurs on Day 95.
🔒 Subscriber Repo: Private-Windows-2022-CIS
📦 Version: v2.0.0
🌐 Target: Windows-2022-CIS
⏱️ Days Tracked: 60
📆 Scheduled Auto-Promotion: 2025-09-12
```

#### ⚠️ Overdue Reminder — Teams
```markdown
⏰ Benchmark Promotion Reminder
⚠️ Benchmark v2.0.0 from `Private-Windows-2022-CIS` is overdue by 3 days.
⏲️ Auto-promotion will occur in 2 days.
🔗 View Issue #43
```

#### ✅ Already Promoted — Teams
```markdown
✅ Benchmark Already Promoted
Benchmark version v2.0.0 is already in Windows-2022-CIS.
📅 Auto-closed on: 2025-09-05
🔗 View Issue #43
```

#### ✅ Already Promoted — Discord
```markdown
✅ Benchmark Promoted To Community
Benchmark v2.0.0 from `Private-Windows-2022-CIS` is already in `Windows-2022-CIS`
🌿 Branch: devel
📅 Auto-closed: 2025-09-05
🔗 Issue: View Issue #43
```

#### ❌ Promotion Blocked — Teams
```markdown
❌ Benchmark Promotion Will Be Blocked
🚫 The community repo **Windows-2022-CIS** does not exist or is missing `devel`.
📢 Please resolve this to enable promotion.
🔒 Repo: Private-Windows-2022-CIS
📦 Version: v2.0.0
```

#### 🚨 Auto-Promotion PR Created — Teams
```markdown
🚨 Benchmark PR Automatically Created 🚨
Version v2.0.0 from Private-Windows-2022-CIS has been proposed for promotion.
🔗 PR: https://github.com/ansible-lockdown/Windows-2022-CIS/pull/99
📅 Days Tracked: 95
🔄 Branch: promote_benchmark_v2_0_0
```

#### 📦 Auto-Promotion PR Created — Discord
```markdown
📦 Benchmark Promotion PR Created: Promote v2.0.0
🔒 Repo: Private-Windows-2022-CIS
🌐 Target: Windows-2022-CIS
🌿 Branch: [promote_benchmark_v2_0_0](https://github.com/ansible-lockdown/Windows-2022-CIS/tree/promote_benchmark_v2_0_0)
🔗 PR: https://github.com/ansible-lockdown/Windows-2022-CIS/pull/99
📅 Days Tracked: 95
```
---

### 13. 🐧 Linux Benchmark Badge Support

This repository also acts as the **central badge hub** for Linux-based benchmark pipelines in addition to Windows.

- All badge JSON files for **Linux CIS** and **Linux STIG** benchmarks are written to the `badges/` directory in this repo
- The same export workflows (`export_badges_public.yml`, `export_badges_private.yml`) handle both **Windows** and **Linux** badge publication
- Example: A benchmark like `Ubuntu-22.04-CIS` will have badges stored at:

```
https://ansible-lockdown.github.io/github_windows_IaC/badges/Ubuntu-22.04-CIS/pre-commit-ci.json
```

> This keeps badge generation consistent and centralized across all platforms for Lockdown.

---

## 🧩 Contributing

Pull requests are welcome. When you open your first PR, a Discord invite will be sent automatically (if enabled). Ensure your repo is configured with the appropriate variables and secrets to execute workflows.
