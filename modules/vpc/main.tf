#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------
resource "aws_vpc" "vpc"{
  cidr_block           = var.vpc_cidr           #IPv4アドレスの範囲をCIDR形式で指定
  instance_tenancy     = "default"              #
  enable_dns_support   = true                   #DNSサーバによる名前解決を有効
  enable_dns_hostnames = true                   #VPC内リソースへのパブリックDNSホスト名自動割り当てを有効
}

#--------------------------------------------------------------
# パブリックサブネット
#--------------------------------------------------------------
resource "aws_subnet" "pub_sub"{
    count = length(var.pub_cidrs)                                   #作成するパブリックサブネットの個数をリストで取得する
    vpc_id = aws_vpc.vpc.id                                         #「リソースの種類.リソース名.属性」で別のリソースのパラメータを参照可能
    cidr_block = element(var.pub_cidrs, count.index)                #現在のインデックスに該当するリストの要素を取得する
    availability_zone = element(var.azs, count.index)               #↑に同じ
    map_public_ip_on_launch = true                                  #このサブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当て
    tags = {                                                        #つけたいタグがあればtagブロックの中で定義
         Name = "${var.name}-pub-${element(var.azs, count.index)}" 
    }
}

#--------------------------------------------------------------
# パブリックサブネットのルートテーブル
#--------------------------------------------------------------
resource "aws_route_table" "pub_rtb"{
    vpc_id = aws_vpc.vpc.id

    route{
        cidr_block = "0.0.0.0/0"                    #すべての通信を許可
        gateway_id = aws_internet_gateway.igw.id    #IGW経由でインターネットと通信するため、ルートの向き先はIGW
    }
    tags = {
        Name = "${var.name}-pub-rtb"
    }
}

#-----------------------------------------------
# パブリックサブネットにルートテーブルを紐づけ
#-----------------------------------------------
resource "aws_route_table_association" "pub_rtb_assoc"{
    count = length(var.pub_cidrs)
    subnet_id = element(aws_subnet.pub_sub.*.id, count.index)   #配列内のすべてのパブリックサブネットに
    route_table_id = aws_route_table.pub_rtb.id                 #ルートテーブル「pub_rtb」を紐づけ
}

#--------------------------------------------------------------
# プライベートサブネット
#--------------------------------------------------------------
resource "aws_subnet" "pri_sub"{
    count = length(var.pri_cidrs)
    vpc_id = aws_vpc.vpc.id         
    cidr_block = element(var.pri_cidrs, count.index)
    availability_zone = element(var.azs, count.index)
    tags = {
        Name = "${var.name}-pri-${element(var.azs, count.index)}"
    }
}

#--------------------------------------------------------------
# プライベートサブネットのルートテーブル
#--------------------------------------------------------------
resource "aws_route_table" "pri_rtb"{
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.name}-pri-rtb"
    }
}

#-----------------------------------------------
# プライベートサブネットにルートテーブルを紐づけ
#-----------------------------------------------
resource "aws_route_table_association" "pri_rtb_assoc"{
    count = length(var.pri_cidrs)
    subnet_id = element(aws_subnet.pri_sub.*.id, count.index)
    route_table_id = aws_route_table.pri_rtb.id
}

#--------------------------------------------------------------
# インターネットゲートウェイ
#--------------------------------------------------------------
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.name}-igw"
  }
}