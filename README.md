# linode-stirling-pdf-iac

Infrastructure as Code (IaC) project that automatically provisions a [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) instance on [Akamai Cloud (Linode)](https://www.linode.com/) using **HCP Terraform** for infrastructure management and **Ansible** for configuration management. Every push to `master` triggers a full end-to-end deployment via GitHub Actions.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                         GitHub Actions                               │
│                                                                      │
│  push to master                                                      │
│       │                                                              │
│       ▼                                                              │
│  ┌─────────────┐    HCP Terraform API    ┌────────────────────────┐  │
│  │  Fetch IP   │ ──────────────────────► │   HCP Terraform Cloud  │  │
│  │  from state │                         │   (auto-applies on VCS │  │
│  └─────┬───────┘                         │    trigger)            │  │
│        │                                 └──────────┬─────────────┘  │
│        ▼                                            │                │
│  ┌─────────────┐          SSH             ┌─────────▼──────────────┐ │
│  │   Ansible   │ ────────────────────────►│   Linode Nanode        │ │
│  │  Playbook   │                          │   Ubuntu 24.04         │ │
│  └─────────────┘                          │   Docker + Stirling PDF│ │
│                                           └────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

## How It Works

This project is split into two independent automation layers:

### 1. Infrastructure — HCP Terraform (Cloud)

Terraform runs **remotely** on [HCP Terraform](https://app.terraform.io). It is connected directly to this GitHub repository via a VCS integration. When you push to `master`, HCP Terraform automatically:

1. Detects the change.
2. Plans the infrastructure diff.
3. Applies it — provisioning or updating the Linode instance.

The Terraform state is stored and managed remotely by HCP Terraform (no local `.tfstate` files).

**What Terraform provisions:**
- A **Linode Nanode** (`g6-nanode-1`) running **Ubuntu 24.04**
- A non-root sudo user (configurable via the `server_user` Terraform variable)
- SSH root login disabled via cloud-init (`PermitRootLogin no`)

### 2. Configuration & Deployment — Ansible (via GitHub Actions)

GitHub Actions handles the Ansible side. On every push to `master`, the workflow:

1. **Fetches the instance IP** from HCP Terraform's API using the `instance_ip` state output.
2. **Generates a fresh `ansible/inventory.ini`** with that IP (file is `.gitignore`d — never hardcoded).
3. **Installs Ansible collections** (`community.docker`).
4. **Runs the Ansible playbook**, which:
   - Waits for SSH to be available (up to 2 minutes).
   - Installs Docker Engine and Docker Compose plugin.
   - Deploys Stirling PDF via Docker Compose on port `8080`.

## Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Main CI/CD pipeline (Ansible + IP retrieval)
│       └── lint.yml            # Super-Linter (Terraform fmt, tflint, Ansible, YAML)
├── ansible/
│   ├── ansible.cfg             # Ansible configuration (inventory path, Python interpreter)
│   ├── requirements.yml        # Ansible Galaxy collections (community.docker)
│   ├── inventory.ini           # Generated at runtime — gitignored
│   └── playbooks/
│       └── site.yml            # Main playbook (wait for SSH + docker role)
│   └── roles/
│       └── docker/
│           ├── tasks/
│           │   └── main.yml    # Install Docker, copy compose file, run container
│           └── files/
│               └── docker-compose.yml  # Stirling PDF service definition
└── terraform/
    ├── main.tf                 # Linode instance resource
    ├── outputs.tf              # Exports instance_ip (sensitive)
    ├── variables.tf            # linode_token, ssh_public_key
    ├── versions.tf             # HCP Terraform cloud backend + provider versions
    └── Makefile                # Local helpers: init, validate, plan, apply, destroy
```

## Prerequisites

### HCP Terraform

- A free account at [app.terraform.io](https://app.terraform.io)
- An organization
- A workspace named `linode-stirling-pdf-iac` with:
  - **VCS integration** connected to this GitHub repository (triggers auto-apply on push)
  - **Execution mode**: Remote
  - The following **Workspace Variables** configured:
    | Variable | Type | Sensitive | Description |
    |---|---|---|---|
    | `linode_token` | Terraform | ✅ Yes | Your Linode API personal access token |
    | `ssh_public_key` | Terraform | ✅ Yes | Your SSH public key (content, not path) |
    | `server_user` | Terraform | No | Non-root username to create on the server |

### GitHub Repository Secrets & Variables

Configure these in **Settings → Secrets and variables → Actions**:

| Name | Kind | Description |
|---|---|---|
| `TF_API_TOKEN` | Secret | HCP Terraform API token (used to read state outputs) |
| `SSH_PRIVATE_KEY` | Secret | Your SSH private key (for Ansible to connect to the server) |
| `TF_WORKSPACE_ID` | Variable | Your HCP Terraform workspace ID (e.g. `ws-xxxxxxxxxx`) |

> **Finding your workspace ID:** In HCP Terraform, go to your workspace → Settings → the ID is shown at the top (`ws-...`).

### Local Tools (for development only)

- [Terraform CLI](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.15
- [jq](https://jqlang.github.io/jq/) (used in the workflow to parse HCP Terraform API responses)

## Deployment Flow

```
git push origin master
```

That's it. Here's what happens automatically:

| Step | Where | What |
|---|---|---|
| VCS trigger detected | HCP Terraform | Terraform plan + apply runs remotely |
| SSH agent setup | GitHub Actions | Loads `SSH_PRIVATE_KEY` into the agent |
| Fetch `instance_ip` | GitHub Actions | Calls HCP Terraform API to get the server IP from state |
| Generate inventory | GitHub Actions | Writes `ansible/inventory.ini` with the live IP |
| Install collections | GitHub Actions | `ansible-galaxy collection install -r requirements.yml` |
| Ansible provisioning | GitHub Actions → Linode | Installs Docker, deploys Stirling PDF |

> **Note:** Terraform and Ansible run in parallel from the same `git push`. HCP Terraform applies infrastructure changes while Ansible configures the server. If the server is newly provisioned, the `wait_for_connection` task in the playbook handles waiting for it to become reachable (up to 2 minutes).

## Stirling PDF

[Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) is a self-hosted, web-based PDF toolkit. Once deployed, it is accessible at:

```
http://<instance-ip>:8080
```

**Container configuration:**
- Image: `stirlingtools/stirling-pdf:2.9.2`
- Port: `8080`
- Data volume: `stirling-data` (configs are persisted)
- Restart policy: `unless-stopped`

## Local Development

Use the Makefile inside `terraform/` for local Terraform operations:

```bash
cd terraform

make init       # terraform init
make validate   # terraform validate
make plan       # terraform plan
make apply      # terraform apply -auto-approve
make destroy    # terraform destroy -auto-approve
make deploy     # validate + plan + apply
make redeploy   # destroy + deploy
```

> You will need a `terraform.tfvars` file (gitignored) with `linode_token` and `ssh_public_key` to run locally.

## Linting

A separate `lint.yml` workflow runs on every push and pull request to all branches. It uses [Super-Linter](https://github.com/super-linter/super-linter) to validate:

- **Terraform**: formatting (`terraform fmt`) and policy (`tflint`)
- **Ansible**: `ansible-lint`
- **YAML**: schema and style

## Security Notes

- The `instance_ip` output is marked `sensitive = true` in Terraform — it will not appear in plan logs.
- The IP is masked in GitHub Actions logs via `echo "::add-mask::$IP"`.
- The generated `ansible/inventory.ini` is `.gitignore`d — the server IP is never committed to the repository.
- Root SSH login is disabled on the server via cloud-init.
- All secrets are stored in GitHub Actions secrets or HCP Terraform workspace variables — never hardcoded.