provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_key_pair" "infra_key" {
  key_name   = "infra_key"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for us-east-2a"
  }
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow 8080 & 22 inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "http access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http access"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    "Name" = "allow_tls"
  }
}
resource "aws_instance" "jenkins_server" {
  count                  = var.jenkins-server
  ami                    = "ami-00eeedc4036573771"
  instance_type          = "t2.large"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = "infra_key"

  tags = {

    "Name" = "jenkins_server ${count.index}"
  }
}

resource "aws_instance" "sonarqube_server" {
  count                  = var.sonarqube-server
  ami                    = "ami-00eeedc4036573771"
  instance_type          = "t2.medium"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = "infra_key"

  tags = {

    "Name" = "sonarqube_server ${count.index}"
  }
}

resource "aws_instance" "nexus_server" {
  count                  = var.nexus-server
  ami                    = "ami-00eeedc4036573771"
  instance_type          = "t2.large"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = "infra_key"

  tags = {
    
    "Name" = "nexus_server ${count.index}"
  }
}

resource "null_resource" "jenkins_server" {

  connection {

    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
 #  host        = aws_instance.jenkins_server.public_ip
    host        = element(aws_instance.jenkins_server.*.public_ip, 0)
  }

  provisioner "file" {
    source      = "Dockerfile.master"
    destination = "/tmp/Dockerfile.master"
  }

  provisioner "file" {
    source      = "plugins.txt"
    destination = "/tmp/plugins.txt"
  }

  provisioner "file" {
    source      = "jenkins-casc.yaml"
    destination = "/tmp/jenkins-casc.yaml"
  }

  provisioner "file" {
    source      = "Dockerfile.slave"
    destination = "/tmp/Dockerfile.slave"
  }

  provisioner "file" {
    source      = "hosts"
    destination = "/tmp/hosts"
  }

  provisioner "file" {
    source      = "ansible.cfg"
    destination = "/tmp/ansible.cfg"
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/tmp/docker-compose.yml"
  }

  provisioner "file" {
    source      = "default.jenkins"
    destination = "/tmp/default.jenkins"
  }

  provisioner "file" {
    source      = "Dockerfile.nginx.jenkins"
    destination = "/tmp/Dockerfile.nginx.jenkins"
  }

  provisioner "file" {
    source      = "docker-compose-nginx-jenkins.yml"
    destination = "/tmp/docker-compose-nginx-jenkins.yml"
  }

  provisioner "file" {
    source      = "docker-compose.sh"
    destination = "/tmp/docker-compose.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install docker.io docker-compose -y",
      "sudo groupadd docker",
      "sudo usermod -a -G docker $USER",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo chmod +x /tmp/docker-compose.yml",
      "sudo chmod +x /tmp/docker-compose-nginx-jenkins.yml",
      "sudo chmod +x /tmp/docker-compose.sh",
      "sh /tmp/docker-compose.sh"
    ]
  }

  depends_on = [
    aws_instance.jenkins_server
  ]
}

resource "null_resource" "sonarqube_server" {

  connection {

    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
 #  host        = aws_instance.sonarqube_server.public_ip
    host        = element(aws_instance.sonarqube_server.*.public_ip, 0)
  }

  provisioner "file" {
    source      = "docker-compose-sonarqube.yml"
    destination = "/tmp/docker-compose-sonarqube.yml"
  }

  provisioner "file" {
    source      = "default.sonarqube"
    destination = "/tmp/default.sonarqube"
  }

  provisioner "file" {
    source      = "Dockerfile.nginx.sonarqube"
    destination = "/tmp/Dockerfile.nginx.sonarqube"
  }

  provisioner "file" {
    source      = "docker-compose-nginx-sonarqube.yml"
    destination = "/tmp/docker-compose-nginx-sonarqube.yml"
  }

  provisioner "file" {
    source      = "sonarqube.sh"
    destination = "/tmp/sonarqube.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo apt-get update",
      "sudo apt-get install docker.io docker-compose -y",
      "sudo groupadd docker",
      "sudo usermod -a -G docker $USER",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo chmod +x /tmp/docker-compose-nginx-sonarqube.yml",
      "sudo chmod +x /tmp/docker-compose-sonarqube.yml",
      "sudo chmod +x /tmp/sonarqube.sh",
      "sh /tmp/sonarqube.sh"
    ]
  }

  depends_on = [
    aws_instance.sonarqube_server
  ]
}

resource "null_resource" "nexus_server" {

  connection {

    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
  # host        = aws_instance.nexus_server.public_ip
    host        = element(aws_instance.nexus_server.*.public_ip, 0)
  }

  provisioner "file" {
    source      = "docker-compose-nexus.yml"
    destination = "/tmp/docker-compose-nexus.yml"
  }

  provisioner "file" {
    source      = "default.nexus"
    destination = "/tmp/default.nexus"
  }

  provisioner "file" {
    source      = "Dockerfile.nginx.nexus"
    destination = "/tmp/Dockerfile.nginx.nexus"
  }

  provisioner "file" {
    source      = "Dockerfile.nexus"
    destination = "/tmp/Dockerfile.nexus"
  }

  provisioner "file" {
    source      = "docker-compose-nginx-nexus.yml"
    destination = "/tmp/docker-compose-nginx-nexus.yml"
  }

  provisioner "file" {
    source      = "nexus.sh"
    destination = "/tmp/nexus.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo apt-get update",
      "sudo apt-get install docker.io docker-compose -y",
      "sudo groupadd docker",
      "sudo usermod -a -G docker $USER",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo chmod +x /tmp/docker-compose-nginx-nexus.yml",
      "sudo chmod +x /tmp/docker-compose-nexus.yml",
      "sudo chmod +x /tmp/nexus.sh",
      "sh /tmp/nexus.sh"
    ]
  }

  depends_on = [
    aws_instance.nexus_server
  ]
}
