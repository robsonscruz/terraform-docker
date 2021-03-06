/* Setup our aws provider */
provider "aws" {
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}
resource "aws_instance" "master" {
  ami           = "${var.ami_version}"
  instance_type = "${var.aws_instance_type}"
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  connection {
    user = "ubuntu"
    private_key = "${file("~/.ssh/longevo-tech.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install git",
      "sudo apt-get install -y apt-transport-https ca-certificates",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'",
      "sudo apt-get update",
      "sudo apt-cache policy docker-engine",
      "sudo apt-get install -y docker-engine wget unzip htop",
      "sudo docker swarm init",
      "sudo docker swarm join-token --quiet worker > /home/ubuntu/token",
      "sudo mkdir -p /${var.path_project} && sudo chown -Rf root:ubuntu /${var.path_project} && sudo chmod 775 -Rf /${var.path_project}",
      "cd /${var.path_project} && wget https://github.com/robsonscruz/docker-web-example/archive/master.zip",
      "cd /${var.path_project} && unzip master.zip && mv docker-web-example-master env-docker && rm master.zip",
      "cd /${var.path_project}/env-docker && mv volumes.yml.dist volumes.yml",
      "sudo curl -o /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo usermod -aG docker $USER",
      "cd /${var.path_project} && wget https://github.com/robsonscruz/api-test/archive/v1.1.zip",
      "cd /${var.path_project} && unzip v1.1.zip",
      "cd /${var.path_project}/env-docker/www && rm -rf api-test",
      "cd /${var.path_project} && mv api-test-1.1 /${var.path_project}/env-docker/www/api-test && rm v1.1.zip",
      "sudo chmod 777 -Rf /${var.path_project}/env-docker/www/api-test/var",
      "cd /${var.path_project}/env-docker && sudo docker-compose build && sudo docker-compose up -d && sudo docker-compose up -d --force-recreate"
    ]
  }
  provisioner "file" {
    source = "proj"
    destination = "/home/ubuntu/"
  }
  tags = {
    Name = "${var.instance_name}-master"
  }
}

resource "aws_instance" "slave" {
  count         = 0
  ami           = "${var.ami_version}"
  instance_type = "${var.aws_instance_type}"
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  connection {
    user = "ubuntu"
    private_key = "${file("~/.ssh/longevo-tech.pem")}"
  }
  provisioner "file" {
    source = "~/.ssh/longevo-tech.pem"
    destination = "/home/ubuntu/key.pem"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install git",
      "sudo apt-get install -y apt-transport-https ca-certificates",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'",
      "sudo apt-get update",
      "sudo apt-cache policy docker-engine",
      "sudo apt-get install -y docker-engine",
      "sudo chmod 400 /home/ubuntu/key.pem",
      "sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i key.pem ubuntu@${aws_instance.master.private_ip}:/home/ubuntu/token .",
      "sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.master.private_ip}:2377"
    ]
  }
  tags = {
    Name = "${var.instance_name}-slave-${count.index}"
  }
}