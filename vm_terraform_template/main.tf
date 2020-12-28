#Variable
##Define Variables for Platform
variable "vsphere_user" {}           #vsphereのユーザー名
variable "vsphere_password" {}       #vsphereのパスワード
variable "vsphere_vc_server" {}         #vCenterのFQDN/IPアドレス
variable "vsphere_datacenter" {}     #vsphereのデータセンター
variable "vsphere_datastore" {}      #vsphereのデータストア
variable "vsphere_cluster" {}        #vsphereのクラスター
variable "vsphere_network_1" {}        #vsphereのネットワーク
variable "vsphere_resource_pool" {}  #ResourcePool名
variable "vsphere_template_name" {}  #プロビジョニングするテンプレート
/*
##ESXホストやネットワークを追加した場合はコメントアウトをはずす
variable "vsphere_host_1" {}         #ESXhost1
variable "vsphere_host_2" {}         #ESXhost2
variable "vsphere_host_3" {}         #ESXhost3
variable "vsphere_network_2" {}        #vsphereのネットワーク
*/

##Network param
variable "pram_domain_name" {}         #仮想マシンが参加するドメイン名
variable "pram_ipv4_subnet" {}         #仮想マシンのネットワークのサブネット
variable "pram_ipv4_gateway" {}        #仮想マシンのネットワークのデフォルトゲートウェイ
variable "pram_dns_server" {}          #仮想マシンが参照するDNSサーバー
variable "pram_ipv4_class" {}          #利用できるクラスCの値を指定
variable "pram_ipv4_host" {}           #プロビジョニングする仮想マシンに割り当てるIPアドレスの最初の値

##Define Variables for Virtual Machines
variable "prov_vm_num" {}            #プロビジョニングする仮想マシンの数
variable "prov_vmname_prefix" {}     #プロビジョニングする仮想マシンの接頭語
variable "prov_cpu_num" {}           #プロビジョニングする仮想マシンのCPUの数
variable "prov_mem_num" {}           #プロビジョニングする仮想マシンのメモリのMB


#Provider
provider "vsphere" {
  user                   = var.vsphere_user
  password               = var.vsphere_password
  vsphere_server         = var.vsphere_vc_server
  allow_unverified_ssl   = true
}

#Data
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_1" {
  name          = var.vsphere_network_1
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

## ESXホストやネットワークを追加した場合に利用
/*
data "vsphere_host" "host_1" {
  name          = var.vsphere_host_1
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "host_2" {
  name          = var.vsphere_host_2
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "host_3" {
  name          = var.vsphere_host_3
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network_2" {
  name          = var.vsphere_network_2
  datacenter_id = data.vsphere_datacenter.dc.id
}
*/

#Resource
resource "vsphere_virtual_machine" "vm" {
  count            = var.prov_vm_num
   name            = "${var.prov_vmname_prefix}${format("%03d",count.index+1)}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

#Resource for VM Specs
  num_cpus = var.prov_cpu_num
  memory   = var.prov_mem_num
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network_1.id
    adapter_type = "vmxnet3"
  }

#Resource for Disks
  disk {
    label            = "disk1"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
        linux_options {
          host_name = "${var.prov_vmname_prefix}${format("%03d",count.index+1)}"
          domain    = var.pram_domain_name
        }        

        network_interface {
          ipv4_address = "${var.pram_ipv4_class}${count.index+var.pram_ipv4_host}"
          ipv4_netmask = var.pram_ipv4_subnet
        }
  
        ipv4_gateway    = var.pram_ipv4_gateway
        dns_server_list = [var.pram_dns_server]
    }
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      password = "Netw0rld"
      host = "${var.pram_ipv4_class}${count.index+var.pram_ipv4_host}"
    }

    inline = [
      "sudo mkdir -p /root/.ssh",
      "sudo touch /root/.ssh/authorized_keys",
      "sudo echo '${tls_private_key.keygen.public_key_openssh}' > authorized_keys",
      "sudo mv authorized_keys /root/.ssh",
      "sudo chown -R root:root /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo chmod 600 /root/.ssh/authorized_keys"
    ]
  }
}
