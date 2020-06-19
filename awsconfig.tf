provider "aws" {
  profile = "satyam"
  region  = "ap-south-1"
}

resource "aws_security_group" "my_security"{
  name        = "my_security"
  description = "Configured for Instance AWS"
  vpc_id      = "vpc-d3b3aebb"

  ingress {
    description = "443 Port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "Allow port 80 and 22"
  }
}


resource "aws_instance"  "sattu_instance" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "keybysatyam2"

  security_groups =  ["${aws_security_group.my_security.name}"]
 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/shailesh/Desktop/AWS/keybysatyam2.pem")
    host        = aws_instance.sattu_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

tags = {
    Name = "Satyam-Amazon-Linux2-AMI"
  }
}

resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.sattu_instance.availability_zone
  size              = 1
tags = {
    Name = "EBS Volume Size 1 GiB"
  }
}

resource "aws_volume_attachment" "volume_one" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs1.id}"
  instance_id = "${aws_instance.sattu_instance.id}"
  force_detach = true
}

output "os_ip" {
  value = aws_instance.sattu_instance.public_ip
}

resource "null_resource" "null_rsrc" {
  depends_on = [
      aws_volume_attachment.volume_one,
    ]


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/shailesh/Desktop/AWS/keybysatyam2.pem")
    host        = aws_instance.sattu_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/satyam9090/TestingAWSgitCloneHTML.git /var/www/html",
    ]
  }
}


resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.sattu_instance.public_ip} > publicip.txt"
  	}
}


resource "aws_s3_bucket" "s3bucketsattu" {
depends_on=[
      null_resource.null_rsrc,
    ]

bucket="s3bucketsattu"
acl ="public-read"

provisioner "local-exec" {
    command = "git clone https://github.com/satyam9090/BlackpinkImage.git  Desktop/Image/Sattu9090"
  }

}



resource "aws_s3_bucket_object" "vg-object" {
   bucket = aws_s3_bucket.s3bucketsattu.bucket
   key    = "blackpink.jpg"
   acl="public-read"
   source = "Desktop/Image/Sattu9090/blackpink.jpg"

}


resource "aws_cloudfront_distribution" "awscloudfrontsattu" {

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.s3bucketsattu.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    

  }



  is_ipv6_enabled     = true
  origin {
  
    domain_name = "${aws_s3_bucket.s3bucketsattu.bucket_regional_domain_name}"
    origin_id   = "${aws_s3_bucket.s3bucketsattu.bucket}"

custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }

  }
 default_root_object = "index.html"
    enabled = true

  custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
    }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
connection {
   type="ssh"
user ="ec2-user"
port=22
private_key=file("C:/Users/shailesh/Desktop/AWS/keybysatyam2.pem")
host=aws_instance.sattu_instance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo -i << EOF",
                           "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.vg-object.key}' width='500' height='500'>\" >> /var/www/html/index.html",
"EOF",
    ]
  }
}
output "cloudfront_ip_addr" {
  value = aws_cloudfront_distribution.awscloudfrontsattu.domain_name
}