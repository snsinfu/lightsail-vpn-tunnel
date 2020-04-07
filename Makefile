
ARTIFACTS = \
  $(CHECKPOINTS) \
  $(GENERATED_FILES)

CHECKPOINTS = \
  _terraform_backend.ok \
  _terraform_resources.ok \
  _connection.ok \
  _provision.ok

GENERATED_FILES = \
  terraform/backend.tfvars \
  terraform/terraform.tfvars \
  ansible/inventory/_10-terraform \
  ansible/inventory/_20-wireguard \
  _known_hosts


.PHONY: all clean destroy ssh

all: _provision.ok
	@:

clean:
	rm -f $(ARTIFACTS)


# INFRASTRUCTURE -------------------------------------------------------------

terraform/backend.tfvars: terraform/backend.tfvars.j2
	scripts/ansible-template $< $@

terraform/terraform.tfvars: terraform/terraform.tfvars.j2
	scripts/ansible-template $< $@

_terraform_backend.ok: terraform/backend.tfvars
	cd terraform; terraform init -backend-config backend.tfvars
	@touch $@

_terraform_resources.ok: terraform/terraform.tfvars _terraform_backend.ok
	cd terraform; terraform apply -auto-approve
	@touch $@

destroy: terraform/terraform.tfvars
	cd terraform; terraform destroy -auto-approve
	@rm -f _terraform_resources.ok


# CONNECTION -----------------------------------------------------------------

ansible/inventory/_10-terraform: _terraform_resources.ok
	{ cd terraform; terraform output inventory; } > $@

_connection.ok: ansible/inventory/_10-terraform
	ansible -o -m ping tunnel
	@touch $@

ssh: _connection.ok
	ssh -F ssh_config $$(scripts/ansible-print -t tunnel "{{ ansible_user }}@{{ ansible_host }}")


# PROVISIONING ---------------------------------------------------------------

_provision.ok: _connection.ok
	ansible-playbook ansible/provision.yml
	@touch $@
