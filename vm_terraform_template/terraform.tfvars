#Define Variables for Platform
vsphere_user           = "administrator@vc.local"      #vsphereのユーザー名
vsphere_password       = "P@ssw0rd"                    #vsphereのパスワード
vsphere_vc_server      = "vcsa2.vc.local"              #vCenterのFQDN/IPアドレス
vsphere_datacenter     = "PIC"                         #vsphereのデータセンター
vsphere_datastore      = "V9KDS5T (4)"                 #vsphereのデータストア
vsphere_cluster        = "UCS-vSAN"                    #vsphereのクラスター
vsphere_network_1      = "VM Network"                  #vsphereのネットワーク
# vsphere_template_name  = "template_ubuntu1804"       #プロビジョニングするテンプレート(ubuntu18.04)
vsphere_template_name = "template_centos7.9.2009"    #プロビジョニングするテンプレート(centos7.9.2009)
vsphere_resource_pool  = "k8s"                         #ResourcePool名

## ESXホストを指定してデプロイする場合はESXホストも変数として指定する
# vsphere_host_1        = "10.42.111.240"              #ESXホスト1
# vsphere_host_2        = "10.42.111.241"              #ESXホスト2
# vsphere_host_3        = "10.42.111.242"              #ESXホスト3
##ネットワークを複数使い分ける用
# vsphere_network_2      = "PIC_Rack3_VLAN450"           #vsphereのネットワーク2

#Network param
pram_domain_name      = "ks-pic.local"              #仮想マシンが参加するドメイン名
pram_ipv4_subnet      = 16                          #仮想マシンのネットワークのサブネット
pram_ipv4_gateway     = "10.42.0.254"               #仮想マシンのネットワークのデフォルトゲートウェイ
pram_dns_server       = "10.42.117.251"           #仮想マシンが参照するDNSサーバー
pram_ipv4_class       = "10.42.117."                #利用できるクラスCの値を指定
pram_ipv4_host        = "121"                       #プロビジョニングする仮想マシンに割り当てるIPアドレスの最初の値
##IPアドレスが固定環境の値。 pram_ipv4_host に指定した値から連続してIPアドレスを割り振る

#Define Variables for Virtual Machines
prov_vm_num           = 7                           #プロビジョニングする仮想マシンの数
prov_vmname_prefix    = "ks-kubeadm-"               #プロビジョニングする仮想マシンの接頭語
prov_cpu_num          = 8                           #プロビジョニングする仮想マシンのCPUの数
prov_mem_num          = 16384                       #プロビジョニングする仮想マシンのメモリのMB

#Linux用のsshkeyの配布
##使用しない場合はssh-key.tfを削除してください。  
sshkey_name       = "example"
sshkey_privatekey_filename   = "example.id_rsa"
sshkey_publickey_filename   = "example.id_rsa.pub"
