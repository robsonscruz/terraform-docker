resource "aws_key_pair" "deployer" {
  public_key = "${file("~/.ssh/longevo-tech.pub")}"
}