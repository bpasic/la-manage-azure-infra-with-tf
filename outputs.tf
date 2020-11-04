output "fe-vm-pip" {
  value = azurerm_windows_virtual_machine.fe-vm.public_ip_address
}

output "fe-vm-ip" {
  value = azurerm_windows_virtual_machine.fe-vm.private_ip_address
}

output "sqlserver" {
  value = azurerm_mssql_server.sqlserver.fully_qualified_domain_name
}