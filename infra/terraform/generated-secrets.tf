resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*-_=+?"
}

resource "random_password" "master_key" {
  length  = 32
  special = false
}

resource "random_password" "service_api_key" {
  length  = 32
  special = false
}
