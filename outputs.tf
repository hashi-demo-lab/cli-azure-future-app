output "futureApp_url" {
  value = "https://${azurerm_public_ip.futureApp-pip.fqdn}"
}
