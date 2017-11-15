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
  provisioner "file" {
    source = "proj"
    destination = "/home/ubuntu/"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod a+x /home/ubuntu/proj/install-urbem.sh",
      "sudo /home/ubuntu/proj/install-urbem.sh"
    ]
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