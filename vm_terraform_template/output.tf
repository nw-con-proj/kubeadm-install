output "Linux-VM" {
  description = "VM Names"
  value       = vsphere_virtual_machine.vm.*.name
}

output "Linux-ip" {
  description = "default ip address of the deployed VM"
  value       = vsphere_virtual_machine.vm.*.default_ip_address
}