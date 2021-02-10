variable "service_instance_id" {}
variable "flavor" {}
variable "server_port" {}

provider "aws"{
    region = "eu-central-1"
}

resource "aws_instance" "SampServer" {
    ami = "ami-03d15d623118d985c"
    instance_type = var.flavor
    vpc_security_group_ids = [ aws_security_group.instance.id ]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    tags = {
      "Name" = "terraform-sample"
    }
}

resource "aws_security_group" "instance" {
  name = "terraform-sample-instance-${var.service_instance_id}"

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow all http request"
    from_port = var.server_port
    protocol = "tcp"
    to_port = var.server_port
  } 
}

output "public_ip" {
    value = aws_instance.SampServer.public_ip
    description = "Public IP address of the server"
}
