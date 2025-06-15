#!/bin/bash

# Update sshd_config
sed -i 's/^#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Nginx
amazon-linux-extras install -y nginx1
systemctl start nginx
systemctl enable nginx

# Install Git
yum install -y git

# Create application directory
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# Clone the React app repository
git clone https://github.com/Khhafeez47/reactapp.git /opt/app/reactapp
cd /opt/app/reactapp

# Write Dockerfile manually
cat > /opt/app/reactapp/Dockerfile-app << 'EOF'
${dockerfile_content}
EOF

# Build the React app Docker image
docker build -t react-app -f Dockerfile-app .

# Run the React app Docker container, mapping container port 80 to host port 8080
docker run -d -p 8080:80 --name react-app-container react-app

# Configure Nginx to reverse proxy to the React app container
cat > /etc/nginx/conf.d/reactapp.conf << 'EOF'
server {
    listen 80;
    server_name haseeb-app.${domain_name};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Restart Nginx to apply configuration
systemctl restart nginx

# Log completion
echo "userapp_data.sh script completed at $(date)" >> /var/log/user-data.log