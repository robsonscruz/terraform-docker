resource "aws_key_pair" "deployer" {
  key_name = "longevo-tech"
  public_key = "${file("~/.ssh/longevo-tech.pub")}"
}