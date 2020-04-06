# VPN tunneling via Amazon Lightsail

Establish a wireguard tunnel between your home and a site behind NAT. User can
access `Server 1a` and `Server 1b` that are internal to `Site 1` from home
network. There can be multiple sites and multipler users.

```
      Site 1                         Lightsail                         Home
===================             ===================                 ==========

 +-----------+                   +---------------+                   +------+
 | Gateway 1 |---[ wireguard ]---| Tunnel server |---[ wireguard ]---| User |
 +-----------+                   +---------------+                   +------+
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

This repository contains code for deploying `Tunnel server` in the diagram.


## Technical details

### Project structure

Terraform deploys a Lightsail server instance and Ansible provisions the
server as a wireguard tunnel server. Terraform and Ansible variables are
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

## Configuration

### Environemnt variables

The terraform configuration uses S3 for a state storage and Lightsail for a
server. Specify the access key/secret of an appropriate IAM user via
environment variables (also default region needs to be specified):

```
AWS_DEFAULT_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

### IAM policy

`{{ BUCKET }}` is your S3 bucket.

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
      "Resource": "*"
    }
  ]
}
```
