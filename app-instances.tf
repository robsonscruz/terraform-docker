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
  root_block_device {
      volume_size = "${var.aws_volume_size}"
  }
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
      "sudo apt-get install -y docker-engine wget zip unzip htop",
      "sudo docker swarm init",
      "sudo docker swarm join-token --quiet worker > /home/ubuntu/token",
      "sudo curl -o /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo mkdir -p /${var.path_project} && sudo chown -Rf root:ubuntu /${var.path_project} && sudo chmod 775 -Rf /${var.path_project}",
      "cd /${var.path_project} && wget https://github.com/robsonscruz/env-urbem/archive/master.zip",
      "cd /${var.path_project} && unzip master.zip && mv env-urbem-master env-urbem && rm master.zip",
      "cd /${var.path_project}/env-urbem && mv volumes.yml.dist volumes.yml",
      "sudo usermod -aG docker $USER",
      "cd /${var.path_project} && wget https://github.com/tilongevo/urbem3.0/archive/v201710251800.zip",
      "cd /${var.path_project} && unzip v201710251800.zip",
      "cd /${var.path_project}/env-urbem/www && rm -rf urbem-prod",
      "cd /${var.path_project} && mv urbem3.0-201710251800 /${var.path_project}/env-urbem/www/urbem-prod && rm v201710251800.zip",
      "cd /${var.path_project} && wget https://github.com/tilongevo/banco-zerado-urbem3.0/archive/master.zip",
      "cd /${var.path_project} && unzip master.zip",
      "cd /${var.path_project} && mv banco-zerado-urbem3.0-master /${var.path_project}/env-urbem/www/urbem-prod/banco-zerado-urbem3.0 && rm banco-zerado-urbem3.0-master.zip",
      "sudo mkdir -p /${var.path_project}/env-urbem/www/urbem-prod/var",
      "sudo chmod 777 -Rf /${var.path_project}/env-urbem/www/urbem-prod/var",
      "cd /${var.path_project}/env-urbem && sudo docker-compose build && sudo docker-compose up -d && sudo docker-compose up -d --force-recreate",
      "sudo docker exec envurbem_web-urbem_1 php /srv/web/urbem/vendor/sensio/distribution-bundle/Resources/bin/build_bootstrap.php",
      "sudo docker exec envurbem_web-urbem_1 php /srv/web/urbem/bin/console cache:clear --no-warmup --env=prod",
      "sudo docker exec envurbem_web-urbem_1 php /srv/web/urbem/bin/console cache:warmup --env=prod",
      "sudo docker exec envurbem_web-urbem_1 /srv/web/urbem/bin/console assetic:dump --no-debug",
      "sudo docker exec envurbem_web-urbem_1 /srv/web/urbem/bin/console assets:install /srv/web/urbem/web --symlink --relative -vvv",
      "sudo chmod 777 -Rf /${var.path_project}/env-urbem/www/urbem-prod/var/*",
      "sudo chmod 777 -Rf /${var.path_project}/env-urbem/www/storage",
      "sudo docker exec envurbem_web-urbem_1 touch /var/www/storage/prefeitura.yml",
      "sudo chmod 777 -Rf /${var.path_project}/env-urbem/www/storage/*",
      "cd /${var.path_project}/env-urbem && sudo docker-compose build && sudo docker-compose up -d && sudo docker-compose up -d --force-recreate",
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
  root_block_device {
      volume_size = "${var.aws_volume_size}"
  }
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
      "sudo apt-get install -y docker-engine",
      "sudo chmod 400 /home/ubuntu/test.pem",
      "sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i test.pem ubuntu@${aws_instance.master.private_ip}:/home/ubuntu/token .",
      "sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.master.private_ip}:2377"
    ]
  }
  tags = {
    Name = "${var.instance_name}-slave-${count.index}"
  }
}