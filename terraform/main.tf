terraform {
  backend "s3" {}
}

resource "aws_lightsail_instance" "tunnel" {
  name              = var.server_name
  availability_zone = var.server_zone
  blueprint_id      = var.server_blueprint
  bundle_id         = var.server_bundle
  user_data         = data.template_file.startup_script.rendered
}

data "template_file" "startup_script" {
  template = file("${path.module}/assets/startup.sh.tpl")
  vars = {
    admin_user            = var.admin_user
    admin_authorized_keys = join("\n", var.admin_public_keys)
    admin_password_hash   = var.admin_password_hash
  }
}

data "template_file" "inventory" {
  template = file("${path.module}/assets/inventory.tpl")
  vars = {
    tunnel_public_address = aws_lightsail_instance.tunnel.public_ip_address
  }
}
