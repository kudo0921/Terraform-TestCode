#--------------------------------------------------------------
# RDS
#--------------------------------------------------------------

resource "aws_db_instance" "rds" {
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.db_instance
  identifier             = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
}

#--------------------------------------------------------------
# サブネットグループ
#--------------------------------------------------------------

resource "aws_db_subnet_group" "rds-subnet-group" {
  name        = var.db_name
  subnet_ids  = var.pri_subnet_ids
}

#--------------------------------------------------------------
# セキュリティグループ
#--------------------------------------------------------------

resource "aws_security_group" "rds-sg" {
  name        = "${var.app_name}-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}