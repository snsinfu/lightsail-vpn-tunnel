# VPN tunneling via Amazon Lightsail

Establish a wireguard tunnel between your home and a site behind NAT. User can
access `Server 1a` and `Server 1b` that are internal to `Site 1` from home
network. There can be multiple sites and multipler users.

```
      Site 1                        Lightsail                         Home
===================             ==================                 ==========

 +-----------+                   +--------------+                   +------+
 | Gateway 1 |---[ wireguard ]---| Relay server |---[ wireguard ]---| User |
 +-----------+                   +--------------+                   +------+
  |      |
  |      V
  |  +-----------+
  |  | Server 1a |
  |  +-----------+
  |
  V
 +-----------+
 | Server 1b |
 +-----------+
```

This repository contains code for deploying `Relay server` in the diagram.

- [Usage](#usage)
- [Technical details](#technical-details)


## Usage

- [Requirements](#requirements)
- [Configuration](#configuration)
- [AWS configuration](#aws-configuration)
- [Deploy](#deploy)

### Requirements

- AWS account
- Terraform (>= 0.12)
- Ansible (>= 2.9)
- jq

### Configuration

Create `config/20-secrets.yml` with the following variables.

```yaml
infra:
  terraform_s3_bucket: ... # Your S3 bucket to store Terraform state
  server_zone: ap-northeast-1a # Relay server's AZ

admin_password: ... # Admin user's password (used for sudo, not ssh)
admin_password_salt: ... # Random salt string used to hash password
admin_public_keys:
  # Admin user's ssh public keys
  - ssh-ed25519 AAAAC3Nza...
  - ...
```

Some notes:

- `server_zone` should be the nearest one to the tunneled sites.

### AWS configuration

Configure AWS account via environment variables:

```
AWS_DEFAULT_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

Root account's access key works, but it is recommended to create a dedicated
IAM user/group for this project. This project uses S3 for a state storage and
Lightsail for a server, so the policy would look like this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::{{ BUCKET }}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::{{ BUCKET }}/lightsail-vpn-tunnel/tfstate"
    },
    {
      "Effect": "Allow",
      "Action": "lightsail:*",
      "Resource": "arn:aws:lightsail:*"
    }
  ]
}
```

Replace `{{ BUCKET }}` with the S3 bucket ID set to `infra/terraform_s3_bucket`
variable.

### Deploy

Type `make` in the project root directory:

```console
$ make
```

Instance takes some time to fully boot up, so Ansible can fail due to
connection failure. In that case retry `make`.

To destroy the server, use `destroy` and `clean` targets:

```console
$ make destroy clean
```


## Technical details

### Project structure

Terraform deploys a Lightsail server instance and Ansible provisions the
server as a wireguard relay server. Terraform and Ansible variables are
centralized in the `config` directory. Makefile integrates everything.

```
/
 |
 +-- config/                      Project configuration
 |    +-- 10-variables.yml        General configurations
 |    +-- 20-secrets.yml          Sensitive configurations (such as password)
 |
 +-- terraform/                   Infrastructure definitions
 |    |
 |    +-- assets/
 |    |    +-- inventory.tpl      Template for Ansible inventory update
 |    |    +-- startup.sh.tpl     Firstboot script for the base Debian image
 |    |
 |    +-- backend.tfvars.j2       Template for backend (S3) variables
 |    +-- terraform.tfvars.j2     Template for terraform variables
 |    +-- main.tf
 |    +-- variables.tf
 |    +-- outputs.tf
 |
 +-- ansible/
 |    |
 |    +-- inventory/
 |    |    +-- hosts              Raw list of hosts
 |    |    +-- _10-terraform      Inventory update from terraform apply
 |    |    +-- _20-wireguard      Inventory update from wireguard deployment
 |    |
 |    +-- assets/                 Config files
 |    |
 |    +-- roles/
 |    |    +-- system/            Basic Debian system tweaks
 |    |    +-- wireguard/         Wireguard deployment
 |    |    +-- iptables/          Iptables deployment
 |    |
 |    +-- vars_plugins/
 |    |    +-- config_vars.py     Load vars from the config directory
 |    |
 |    +-- provision.yml
 |
 +-- scripts/                     Utility scripts
 |    +-- ansible-print           Print Ansible expression
 |    +-- ansible-template        Render template locally
 |
 +-- Makefile                     Task runner
 +-- ansible.cfg                  Ansible config
 +-- .vaultpass                   Ansible Vault password file
```
