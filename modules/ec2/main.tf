#-----------------------------------------------
# EC2インスタンス
#-----------------------------------------------
resource "aws_instance" "ec2"{
    ami = data.aws_ami.amazon_linux_2.id                      #dataブロックで取得した最新のAMIIDを代入する。
    instance_type = "${var.instance_type}"                    #インスタンスタイプを指定
    subnet_id = "${var.pub_subnet_ids[0]}"                    #EC2を配置するサブネットを指定
    associate_public_ip_address = "true"                      #パブリックIPの付与　※サブネットとインスタンスの両方でtrueにしないとパブリックIPは付与されない(インスタンスの設定が優先されるため)
    vpc_security_group_ids = [aws_security_group.ec2-sg.id]   #セキュリティグループを指定
    iam_instance_profile = "${var.iam_instance_profile_name}" #インスタンスプロファイル(IAMロールのコンテナ)としてIAMロールを指定

    ebs_block_device {
      device_name = "/dev/xvda"
      volume_size = 10
    }
}

data "aws_ami" "amazon_linux_2"{                  #dataブロックを定義し、最新のAmazon-linux-2のAMIIDを取得する。
    most_recent = true                            #より最近の
    owners = ["amazon"]

    filter{
        name = "owner-alias"
        values = ["amazon"]
    }

    filter{
        name = "name"                             #探してくるAMIの名前を指定する
        values = ["amzn2-ami-hvm-*-x86_64-ebs"]   #ワイルドカードを用いて条件を緩めることでどの日付のAMIでもヒットする
    }                                             #19行目の「most_recent = true」によって複数ヒットしたAMIのうち最新のものを指定する
}

#-----------------------------------------------
# キーペア
#-----------------------------------------------
resource "aws_key_pair" "ec2-key" {                   #公開鍵を生成し、EC2インスタンスに登録
  key_name   = "common-ssh"
  public_key = tls_private_key._.public_key_openssh   #秘密鍵とのペア(公開鍵)を作成する
}

resource "tls_private_key" "_" {                      #秘密鍵の生成(秘密鍵はSecretManagerに追加されるためローカルでは管理しない)
  algorithm = "RSA"                                   #鍵を生成するアルゴリズムを指定
  rsa_bits  = 4096                                    #ここで生成された秘密鍵はtfstateファイルに暗号化されていない形で保存されるため、本番環境での使用は推奨されていない
}

#-----------------------------------------------
# セキュリティグループ
#-----------------------------------------------
resource "aws_security_group" "ec2-sg" {
  name        = "${var.app_name}-ec2-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = { for i in var.ingress_config : i.port => i }

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}