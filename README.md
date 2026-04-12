# Containers Configuration

## Overview
`containers.yml` defines LXC/Incus containers that run on the infrastructure. Each entry creates a development environment for a team member.

## Quick Start Workflow

### 1. Clone the Repository
```bash
git clone https://github.com/tinkerhub/infried.git
cd infried
```

### 2. Create a Feature Branch
```bash
git checkout -b "feat/add-member-NAME"
```
Replace `NAME` with the member's username (e.g., `feat/add-member-jasim`).

### 3. Update containers.yml
Edit `containers/containers.yml` and add the new container configuration (see section below).

### 4. Commit and Create PR
```bash
git add containers/containers.yml
git commit -m "feat: add container for member-NAME"
git push origin feat/add-member-NAME
```
Then create a pull request on GitHub.

---

## How to Add a Container

Copy this template and update the values:

```yaml
- name: username
  bridge: incusbr-members
  cpu: 4
  memory: 4GB
  disk: 5GB
  ssh_port: 222X
  user: username
  ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... full_key"
```

## Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| **name** | Container identifier (unique) | `member-sexy-jasim` |
| **bridge** | Network bridge to connect | `incusbr-members` (standard, dont change unless uk what ur doing ) |
| **cpu** | CPU cores allocated | `4` |
| **memory** | RAM allocation | `4GB` |
| **disk** | Storage space | `5GB` |
| **ssh_port** | VPS port for SSH access | `2223` (must be unique) |
| **user** | Linux username inside container | `jasim` |
| **ssh_key** | Public SSH key (ed25519 preferred) | Full key string |

## Getting SSH Key

if you dont have a ssh key pair, generate it via, the command below and copy the **public key**:
```bash
ssh-keygen -t ed25519 -C "user@domain.com"
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output starting with `ssh-ed25519`.

## Rules

- **Port numbers must be unique** — no duplicates
- **Names must be unique** — used as container identifier
- **Bridge should be** `incusbr-members` for member containers
- **Indentation matters** — YAML format is strict (use spaces, not tabs)

## Example: Adding a New Member

User provides:
- Name: `jasi`
- SSH key: `ssh-ed25519 AAAAC3NzaC1lZDI1...`
- Preferred port: `2225`

Add to `containers.yml`:
```yaml
- name: member-jasi
  bridge: incusbr-members
  cpu: 4
  memory: 4GB
  disk: 5GB
  ssh_port: 2225
  user: jasi
  ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1..."
```

Then commit and push your branch to create a pull request.

