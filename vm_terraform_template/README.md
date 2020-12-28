# Terraform でVMをデプロイ
オンプレのvSphere環境に対して、事前に作成済みのOSテンプレートを利用して、仮想マシンをデプロイする。  

- terraform.tfvars: 環境のパラメータを指定
- main.tf: vSphere環境の設定と実際のリソースの作成。基本は変更不要。

## terraform.tfvars
デプロイする環境に合わせてパラメータを調整する

## main.tf
"terraform.tfvars"でESXホストの追加やネットワークの設定を追加した場合には変更が必要。  
変更箇所はコメントアウトしてあるので、コメントを外すだけ。

**2020/12/23 時点でesx hostを選択する方法などは未完成**




