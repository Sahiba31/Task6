provider "kubernetes" {
  config_context_cluster = "minikube"
}

resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress"
}

  spec {
    replicas = 1
    selector {
     match_labels = {
     env = "production"
     region = "IN"
     App = "wordpress"
     }
     match_expressions {
      key = "env"
      operator = "In"
      values   = ["production", "webserver"]
     }
  }
    template {
      metadata {
        labels = {
          env = "production"
          region = "IN"
          App = "wordpress"
        }
      }
      spec {
       container {
        image = "wordpress"
        name  = "mywordpress-cont"
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress"
  }
  spec {
    selector = {
      App = kubernetes_deployment.wordpress.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

provider "aws" {
  region   = "ap-south-1"
  profile  = "sahiba"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  identifier           = "mydb"
  name                 = "mydb"
  username             = "sahiba"
  password             = "sahiba123"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = true
  skip_final_snapshot = true
}

data "http" "myip"{
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "sg" {
  name        = "mysql-sg"

  ingress {
    description = "for mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-sg"
  }
}

output "dns"{
  value = aws_db_instance.default.address
}