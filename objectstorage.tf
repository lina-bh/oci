resource "oci_objectstorage_bucket" "tfstate" {
  lifecycle {
    prevent_destroy = true
  }

  compartment_id = data.oci_objectstorage_namespace.ns.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "tfstate"
}
