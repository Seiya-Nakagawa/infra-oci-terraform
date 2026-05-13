# Bastion Service
resource "oci_bastion_bastion" "news_check_bastion" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = oci_core_subnet.news_check_public_subnet.id
  client_cidr_block_allow_list = [var.allowed_client_cidr]
  name                         = "${var.project_name}-bastion"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
  }
}

output "bastion_ocid" {
  value = oci_bastion_bastion.news_check_bastion.id
}
