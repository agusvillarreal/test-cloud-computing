#!/bin/bash

# User data script for EC2 instance
# This script installs and configures Apache web server

# Update system packages
yum update -y

# Install Apache web server
yum install -y httpd

# Start and enable Apache service
systemctl start httpd
systemctl enable httpd

# Create a simple HTML page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to ${project_name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to ${project_name}!</h1>
        <div class="info">
            <h2>Instance Information</h2>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Public IP:</strong> $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
            <p><strong>Launch Time:</strong> $(date)</p>
        </div>
        <p>This EC2 instance was created using OpenTofu (Terraform)!</p>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.html

# Restart Apache to ensure everything is working
systemctl restart httpd

# Log the completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
