# This directory contains example configurations for cost optimization and security.

# Example: security_group.tf (Terraform for Security Group)
# resource "aws_security_group" "web_sg" {
#   name        = "web-sg"
#   description = "Allow web traffic"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# Example: iam_policy.json (IAM Policy for S3 Read-Only Access)
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "s3:Get*",
#                 "s3:List*"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::your-bucket-name",
#                 "arn:aws:s3:::your-bucket-name/*"
#             ]
#         }
#     ]
# }
