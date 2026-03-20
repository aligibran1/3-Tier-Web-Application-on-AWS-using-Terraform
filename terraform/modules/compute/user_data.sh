#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Install web server
apt-get install -y nginx

# Create health check endpoint
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>3-Tier Web App - Running</title>
</head>
<body>
    <h1>Application is running on ${project_name}</h1>
    <p>Instance: <code>$(hostname)</code></p>
    <p>Region: <code>$(ec2-metadata --availability-zone | cut -d ' ' -f 2)</code></p>
</body>
</html>
EOF

# Start nginx
systemctl start nginx
systemctl enable nginx

# CloudWatch Agent Configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/${project_name}",
            "log_stream_name": "{instance_id}/nginx/access.log"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/${project_name}",
            "log_stream_name": "{instance_id}/nginx/error.log"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
