# Midterm Project 2 — Infrastructure as Code with Terraform & Azure ACI

> Cloud Computing & DevOps Engineering — Instructor: M.Sc. Abdelhakim Rashid

A containerized web application deployed to **Azure Container Instances (ACI)** using **Infrastructure as Code (Terraform)**, with a fully automated **CI/CD pipeline (GitHub Actions)** that includes a **manual approval gate** for production.

---

## 👥 Authors

| Name | Student ID |
|------|------------|
| Hussain Saleem | 4891 |
| Ramadan Swedik | 4761 |

**Repository:** https://github.com/hussain14saleem1-lgtm/cloudscale-proj2

---

## 📖 Project Description

CloudScale is a startup that needs to deploy a containerized web app to Azure without managing virtual machines. We solved this using a serverless container platform — **Azure Container Instances (ACI)** — provisioned entirely through **Infrastructure as Code**.

The solution:

1. A custom **Docker image** (an `nginx`-based web page showing the team's names) is built and published to **Docker Hub**.
2. **Terraform** provisions an Azure **Resource Group** and an **Azure Container Instance** that runs the image, exposing it on a public IP with a DNS name.
3. A **GitHub Actions** pipeline automates everything: it runs `terraform plan` on every Pull Request and `terraform apply` on every push to `main`.
4. A **manual approval gate** (GitHub Environment) requires a human to approve before any production deployment runs.
5. **GitHub Secrets** store the Azure service-principal credentials so the pipeline can authenticate securely.

---

## 🏗️ Architecture

```text
                         +---------------------------+
                         |   Developers (2 laptops)  |
                         |   Hussain  &  Ramadan     |
                         +-------------+-------------+
                                       | git push / Pull Request
                                       v
                         +---------------------------+
                         |    GitHub Repository      |
                         |    cloudscale-proj2       |
                         +-------------+-------------+
                                       |
              +------------------------+------------------------+
              |  Pull Request                      Push to main |
              v                                                 v
   +---------------------+                        +-----------------------------+
   |  terraform plan     |                        |  MANUAL APPROVAL GATE       |
   |  (GitHub Actions)   |                        |  (production environment)   |
   +---------------------+                        +--------------+--------------+
                                                                 | approved
                                                                 v
                                                   +-----------------------------+
                                                   |  terraform apply            |
                                                   |  (GitHub Actions)           |
                                                   +--------------+--------------+
                                                                  | Service Principal
                                                                  v
   +-----------------+   image pull    +-------------------------------------------+
   |   Docker Hub    | --------------> |              Microsoft Azure              |
   | hussain1s/      |                 |  Resource Group: hussain-proj2-aci-rg     |
   | cloudscale-proj2|                 |    -> Azure Container Instance (ACI)       |
   +-----------------+                 |       Public IP + DNS (port 80)           |
                                       |  Storage Account: terraform remote state  |
                                       +---------------------+---------------------+
                                                             ^
                                                             | http://<dns>.azurecontainer.io
                                                     +---------------+
                                                     |   End User    |
                                                     +---------------+
```

**Components:**

- **Docker / Docker Hub** — builds and stores the container image.
- **Terraform** — defines and provisions all Azure resources (IaC).
- **Azure Resource Group + Container Instance** — runs the container with a public IP and DNS label.
- **Azure Storage Account** — remote backend storing the Terraform state file.
- **GitHub Actions** — automated plan/apply pipeline.
- **GitHub Environment (`production`)** — enforces manual approval before apply.

---

## 🧰 Technology Stack

| Layer | Technology |
|-------|-----------|
| Containerization | Docker, Docker Hub |
| Web server | nginx (alpine) |
| Infrastructure as Code | Terraform (`azurerm` provider) |
| Cloud | Azure Container Instances, Resource Group, Storage Account |
| CI/CD | GitHub Actions |
| Approval gate | GitHub Environments (required reviewers) |
| Secrets | GitHub Actions Secrets + Azure Service Principal |

---

## 📁 Repository Structure

```
cloudscale-proj2/
├── Dockerfile                      # Builds the nginx web app image
├── index.html                      # Custom web page (team names)
├── providers.tf                    # Azure provider + remote backend
├── variables.tf                    # Input variables (7 variables)
├── main.tf                         # Resource group + Container Instance + tags
├── outputs.tf                      # Outputs (IP, FQDN, URL, RG name)
├── .gitignore                      # Excludes Terraform state & secrets
├── .terraform.lock.hcl             # Provider version lock
├── .github/
│   └── workflows/
│       └── terraform.yml           # CI/CD pipeline
└── screenshots/                    # Evidence screenshots (1–8)
```

---

## 🐳 Docker — Build & Push Instructions

The web application is a static page served by `nginx`, baked into a Docker image.

**Dockerfile:**
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

**Build and push:**
```bash
# Build the image
docker build -t hussain1s/cloudscale-proj2:latest .

# Log in to Docker Hub
docker login

# Push the image (public repository)
docker push hussain1s/cloudscale-proj2:latest
```

**Public image:** https://hub.docker.com/r/hussain1s/cloudscale-proj2

---

## ☁️ Terraform — Setup Instructions

### Prerequisites
- Terraform ≥ 1.3
- Azure CLI (logged in via `az login`)
- An Azure subscription (Azure for Students)

### Remote backend (created once, before `terraform init`)
The Terraform state is stored remotely in an Azure Storage Account:

```bash
az group create --name hussain-tfstate-rg --location switzerlandnorth

az storage account create \
  --name hussaintfstate2026 \
  --resource-group hussain-tfstate-rg \
  --location switzerlandnorth \
  --sku Standard_LRS

az storage container create --name tfstate --account-name hussaintfstate2026
```

### Deploy the infrastructure
```bash
terraform init      # downloads provider + connects to remote backend
terraform plan      # preview the changes
terraform apply     # create the resources (type "yes")
```

### Outputs produced
| Output | Example value |
|--------|---------------|
| `container_public_ip` | `20.250.82.120` |
| `container_fqdn` | `hussain-proj2-app.switzerlandnorth.azurecontainer.io` |
| `application_url` | `http://hussain-proj2-app.switzerlandnorth.azurecontainer.io` |
| `resource_group_name` | `hussain-proj2-aci-rg` |

### Resource tags (applied to every resource)
| Tag | Value |
|-----|-------|
| Project | Project2 |
| Environment | production |
| StudentName | Hussain Saleem |
| Owner | Ramadan Swedik |
| ManagedBy | Terraform |

---

## ⚙️ GitHub Actions Workflow Explanation

The pipeline is defined in `.github/workflows/terraform.yml` and has **two jobs**:

### 1. `terraform-plan` — runs on every Pull Request to `main`
```yaml
if: github.event_name == 'pull_request'
```
When a team member opens a Pull Request, this job runs `terraform init` + `terraform plan`, showing exactly what infrastructure changes the PR would make — **before** anything is applied. This lets the team review changes safely.

### 2. `terraform-apply` — runs on every push to `main`, behind an approval gate
```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
environment: production
```
When a PR is merged (a push to `main`), this job runs `terraform apply -auto-approve`. Because it targets the **`production` environment**, GitHub **pauses the job and waits for a required reviewer to approve** before it runs — this is the **manual approval gate**.

### Azure authentication (GitHub Secrets)
The pipeline logs into Azure using a **Service Principal** stored as encrypted **GitHub Secrets**:

| Secret | Purpose |
|--------|---------|
| `ARM_CLIENT_ID` | Service principal app ID |
| `ARM_CLIENT_SECRET` | Service principal password |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure tenant ID |

These are read by Terraform's `azurerm` provider automatically as environment variables.

### Workflow logic summary
| Event | Plan | Apply | Approval |
|-------|------|-------|----------|
| Pull Request → main | ✅ runs | ⏭️ skipped | — |
| Push/merge → main | ⏭️ skipped | ✅ runs | 🔒 required |

---

## 📸 Screenshots

### 1. Docker image build successful
![Docker build](screenshots/01-docker-build.png)

### 2. Docker image pushed to Docker Hub
![Docker push](screenshots/02-docker-push.png)

### 3. `terraform plan` output
![Terraform plan](screenshots/03-tf-plan.png)

### 4. `terraform apply` output
![Terraform apply](screenshots/04-tf-apply.png)

### 5. GitHub Actions — successful plan on Pull Request
![Actions plan on PR](screenshots/05-actions-plan-pr.png)

### 6. GitHub Actions — approved apply
![Actions approved apply](screenshots/06-actions-apply.png)

### 7. Browser showing the live containerized web app
![Live app](screenshots/07-browser-app.png)

### 8. Azure Portal showing the resource group and resources
![Azure Portal](screenshots/08-azure-portal.png)

---

## 🪜 Step-by-Step Detailed Solution

> Presented in the same style as the course lab: each step lists the exact command and the **expected output**.

### Step 1: Install the Tools
Install Git, Docker Desktop, Azure CLI, and Terraform, then verify each:
```powershell
git --version
docker --version
az --version
terraform --version
```
**Expected output:** each command prints a version number (no errors).

---

### Step 2: Build the Docker Web Application

**Step 2.1 — Create `index.html`:** a styled page that displays the team members' names (Hussain Saleem in green, Ramadan Swedik in red).

**Step 2.2 — Create the `Dockerfile`:**
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

**Step 2.3 — Build the image:**
```powershell
docker build -t hussain1s/cloudscale-proj2:latest .
```
**Expected output:** `[+] Building ... FINISHED` ending with `naming to docker.io/hussain1s/cloudscale-proj2:latest`.

**Step 2.4 — Test locally:**
```powershell
docker run -d -p 8080:80 --name proj2test hussain1s/cloudscale-proj2:latest
```
Open `http://localhost:8080` — the page should render.

**Step 2.5 — Push to Docker Hub:**
```powershell
docker login
docker push hussain1s/cloudscale-proj2:latest
```
**Expected output:** all layers `Pushed` and a final `latest: digest: sha256:...` line.

---

### Step 3: Initialize Git and Push to GitHub

**Step 3.1 — Initialize and make the first commit:**
```powershell
git init -b main
git add .
git commit -m "Add Dockerfile and web app"
```

**Step 3.2 — Create a public repo on GitHub, then connect and push:**
```powershell
git remote add origin https://github.com/hussain14saleem1-lgtm/cloudscale-proj2.git
git push -u origin main
```
**Expected output:** `* [new branch] main -> main`.

---

### Step 4: Create the Terraform Remote Backend (Azure)

**Step 4.1 — Log in to Azure:**
```powershell
az login
```

**Step 4.2 — Create the state storage (resource group, storage account, blob container):**
```powershell
az group create --name hussain-tfstate-rg --location switzerlandnorth

az storage account create --name hussaintfstate2026 --resource-group hussain-tfstate-rg --location switzerlandnorth --sku Standard_LRS

az storage container create --name tfstate --account-name hussaintfstate2026
```
**Expected output:** `"provisioningState": "Succeeded"` and `"created": true`.

---

### Step 5: Write the Terraform Configuration
Create the five configuration files (full contents are in the repository):

| File | Purpose |
|------|---------|
| `providers.tf` | `azurerm` provider + remote backend |
| `variables.tf` | 7 input variables |
| `main.tf` | resource group + container instance + tags (`local.common_tags`) |
| `outputs.tf` | 4 outputs (IP, FQDN, URL, RG name) |
| `.gitignore` | excludes Terraform state files |

Then commit and push:
```powershell
git add .
git commit -m "Add Terraform configuration"
git push
```

---

### Step 6: Deploy the Infrastructure

**Step 6.1 — Initialize Terraform:**
```powershell
terraform init
```
**Expected output:** `Terraform has been successfully initialized!`

**Step 6.2 — Preview the changes:**
```powershell
terraform plan
```
**Expected output:** `Plan: 2 to add, 0 to change, 0 to destroy.`

**Step 6.3 — Apply (type `yes` when prompted):**
```powershell
terraform apply
```
**Expected output:**
```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
application_url     = "http://hussain-proj2-app.switzerlandnorth.azurecontainer.io"
container_fqdn      = "hussain-proj2-app.switzerlandnorth.azurecontainer.io"
container_public_ip = "20.250.82.120"
resource_group_name = "hussain-proj2-aci-rg"
```

**Step 6.4 — Verify:** open the `application_url` in a browser (live app), and confirm the resource group + container instance in the **Azure Portal**.

---

### Step 7: Configure the CI/CD Pipeline

**Step 7.1 — Create an Azure Service Principal** (the credentials GitHub Actions uses to log in to Azure):
```powershell
az ad sp create-for-rbac --name "hussain-proj2-sp" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>
```
Copy the `appId`, `password`, and `tenant` from the output.

**Step 7.2 — Add 4 GitHub Secrets** (Settings → Secrets and variables → Actions):
`ARM_CLIENT_ID` (appId), `ARM_CLIENT_SECRET` (password), `ARM_TENANT_ID` (tenant), `ARM_SUBSCRIPTION_ID`.

**Step 7.3 — Create the approval gate:** Settings → Environments → **New environment** → name it `production` → enable **Required reviewers** → add yourself → **Save protection rules**.

**Step 7.4 — Create the workflow** `.github/workflows/terraform.yml` (plan on PR, apply on push to `main` behind the `production` environment), then commit and push:
```powershell
git add .
git commit -m "Add GitHub Actions CI/CD workflow"
git push
```

**Step 7.5 — Approve the deployment:** Actions tab → open the run → the **Terraform Apply** job shows *Waiting* → click **Review deployments** → check **production** → **Approve and deploy**.
**Expected output:** the apply job completes green after approval.

---

### Step 8: Team Collaboration via Pull Request

**Step 8.1 — Add the teammate as a collaborator** (Settings → Collaborators → Add people); the teammate accepts the email invite.

**Step 8.2 — On the second laptop, clone the repo and create a branch:**
```powershell
git clone https://github.com/hussain14saleem1-lgtm/cloudscale-proj2.git
cd cloudscale-proj2
git checkout -b owner
```

**Step 8.3 — Make a meaningful change** (add an `owner` variable + `Owner`/`ManagedBy` tags), then commit and push:
```powershell
git add .
git commit -m "Add resource ownership tags (Owner and ManagedBy)"
git push -u origin owner
```

**Step 8.4 — Open a Pull Request** (base `main` ← compare `owner`).
**Expected output:** the **Terraform Plan (on PR)** check runs and passes; **Terraform Apply** is skipped.
```text
Plan: 0 to add, 2 to change, 0 to destroy.
```

**Step 8.5 — Merge the Pull Request.** The push to `main` triggers **Terraform Apply**, which waits for approval → **Approve and deploy** → the tag changes are applied to the live resources.

**Result:** the repository shows commit history from **both team members**, and the full DevOps cycle is demonstrated: *propose → plan → review → approve → deploy*.

---

## 🧹 Cleanup (optional)

To remove all billed Azure resources after grading:
```bash
terraform destroy
```
The remote-state resources can be removed with:
```bash
az group delete --name hussain-tfstate-rg --yes
```

---

## ✅ Requirements Checklist

- [x] Valid Dockerfile, exposes port 80, custom message with names, pushed to public Docker Hub
- [x] Resource Group + ACI named with student name, public IP, DNS label
- [x] All resources tagged (Project, Environment, StudentName)
- [x] `terraform plan` on every PR to main
- [x] `terraform apply` on every push to main
- [x] Manual approval gate before apply
- [x] GitHub Secrets for Azure authentication
- [x] All required files (providers/variables/main/outputs/.gitignore/workflow/README)
- [x] Contributions from all team members + multiple commits
- [x] All 8 screenshots embedded