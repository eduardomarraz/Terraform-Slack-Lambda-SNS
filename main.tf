# Define el proveedor de AWS
provider "aws" {
  region = "us-east-1"
}

# Define el par de claves para acceder a la instancia EC2
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("/home/ec2-user/environment/deployer-key.pub")
}

# Define el grupo de seguridad para permitir el tráfico HTTP y SSH
resource "aws_security_group" "allow_http_ssh" {
  name_prefix = "allow_http_ssh_"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define la instancia EC2
resource "aws_instance" "web" {
  ami                    = "ami-01b799c439fd5516a" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  security_groups        = [aws_security_group.allow_http_ssh.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              sudo yum install -y php php-cli php-json php-mbstring
              cd /var/www/html
              sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
              sudo php composer-setup.php
              sudo php -r "unlink('composer-setup.php');"
              sudo php composer.phar require aws/aws-sdk-php
              sudo systemctl restart httpd
              echo '<!DOCTYPE html>
              <html lang="en">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Contact Form</title>
              </head>
              <body>
                  <h1>Contact Form</h1>
                  <form action="submit.php" method="POST">
                      <label for="name">Name:</label><br>
                      <input type="text" id="name" name="name" required><br>
                      <label for="email">Email:</label><br>
                      <input type="email" id="email" name="email" required><br>
                      <label for="message">Message:</label><br>
                      <textarea id="message" name="message" rows="4" required></textarea><br>
                      <input type="submit" value="Submit">
                  </form>
              </body>
              </html>' > /var/www/html/index.html
              echo '<?php
              require 'vendor/autoload.php';
              use Aws\Sns\SnsClient;
              use Aws\Exception\AwsException;
              if ($_SERVER["REQUEST_METHOD"] == "POST") {
                  $name = $_POST["name"];
                  $email = $_POST["email"];
                  $message = $_POST["message"];
                  $snsTopicArn = '${aws_sns_topic.contact_form.arn}';
                  $snsClient = new SnsClient([
                      'version' => 'latest',
                      'region' => 'us-east-1'
                  ]);
                  $messageToSend = json_encode([
                      'email' => $email,
                      'name' => $name,
                      'message' => $message
                  ]);
                  try {
                      $snsClient->publish([
                          'TopicArn' => $snsTopicArn,
                          'Message' => $messageToSend
                      ]);
                      echo "Message sent successfully.";
                  } catch (AwsException $e) {
                      echo "Error sending message: " . $e->getMessage();
                  }
              } else {
                  http_response_code(405);
                  echo "Method Not Allowed";
              }
              ?>' > /var/www/html/submit.php
              EOF

  tags = {
    Name = "Terraform-EC2-Instance"
  }
}

# Define el tópico SNS
resource "aws_sns_topic" "contact_form" {
  name = "contact-form-topic"
}

# Define la función Lambda
resource "aws_lambda_function" "slack_notification" {
  filename         = "lambda_function.zip"
  function_name    = "slackNotification"
  role             = "arn:aws:iam::180992220281:role/LabRole"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Crear la suscripción del SNS al Lambda
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.contact_form.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notification.arn
}

# Crear la suscripción del SNS para el email
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.contact_form.arn
  protocol  = "email"
  endpoint  = "eduardomr_@hotmail.com"
}

# Permisos para que SNS invoque Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.contact_form.arn
}



# Output de la IP pública de la instancia
output "instance_ip" {
  value = aws_instance.web.public_ip
}
