# 3-Tier Web Application on AWS

A production-ready, highly available 3-tier web application architecture built with Terraform on AWS.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Internet Users                    │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Application Load Balancer   │
        │   (Public Subnets - AZ1/2)   │
        └──────────────────┬───────────┘
                           │
        ┌──────────────────┴───────────────────┐
        │                                      │
        ▼                                      ▼
  ┌──────────────┐                    ┌──────────────┐
  │ EC2 Instance │                    │ EC2 Instance │
  │  (AZ1 - ASG) │                    │  (AZ2 - ASG) │
  │ Private      │                    │ Private      │
  └──────┬───────┘                    └────┬─────────┘
         └──────────────────┬───────────────┘
                            │
        ┌───────────────────┴────────────────┐
        │                                    │
        ▼                                    ▼
  ┌──────────────────┐             ┌──────────────────┐
  │  RDS Primary     │             │  RDS Standby     │
  │  (AZ1)           │◄───Sync────►│  (AZ2)           │
  │  Multi-AZ        │             │  (Auto Failover) │
  └──────────────────┘             └──────────────────┘
```

## Features

### High Availability
- **Multi-AZ Deployment:** Resources spread across 2+ Availability Zones
- **Auto Scaling:** EC2 instances automatically scale based on demand (2-6 instances)
- **RDS Multi-AZ:** Database replication with automatic failover
- **Load Balancing:** Application Load Balancer distributes traffic

### Security
- **Network Isolation:** Public, private application, and private database subnets
- **Security Groups:** Layered access control (ALB → EC2 → RDS)
- **No SSH Access:** Uses AWS Systems Manager Session Manager for secure access
- **IAM Roles:** Least privilege roles for EC2 instances
- **Encrypted Database:** KMS encryption for RDS storage
- **Encrypted Backups:** Automated backups with encryption

### Monitoring & Logging
- **CloudWatch Logs:** EC2 application logs sent to CloudWatch
- **CloudWatch Metrics:** CPU, memory, database connections tracked
- **CloudWatch Alarms:** Automatic alerts for unhealthy instances, high CPU, low storage
- **Performance Insights:** RDS performance monitoring enabled

### Networking
- **VPC with 3 Subnet Tiers:**
  - Public subnets (ALB access)
  - Private application subnets (EC2 instances)
  - Private database subnets (RDS database)
- **Internet Gateway:** Public subnet internet access
- **NAT Gateway:** Private subnet outbound internet access
- **Route Tables:** Proper routing for all subnet tiers

## Folder Structure

```
project-1-3-tier-web-app/
├── terraform/
│   ├── provider.tf              # AWS provider configuration
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── main.tf                  # Module calls
│   ├── terraform.tfvars.example # Example variable values
│   └── modules/
│       ├── vpc/                 # VPC, subnets, gateways
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── security/            # Security groups, IAM roles
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── compute/             # ALB, ASG, launch templates
│       │   ├── main.tf
│       │   ├── user_data.sh
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── database/            # RDS, encryption, monitoring
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── README.md                    # This file
```

## Prerequisites

- **Terraform** >= 1.0
- **AWS Account** with appropriate IAM permissions
- **AWS CLI** configured with credentials
- **GitHub Account** (optional, for version control)

## Deployment Instructions

### Step 1: Clone or Download
```bash
git clone <your-repo-url>
cd project-1-3-tier-web-app/terraform
```

### Step 2: Prepare Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your desired values
# ⚠️ IMPORTANT: Change db_password to a strong password!
nano terraform.tfvars
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Review Plan
```bash
terraform plan
```

### Step 5: Deploy
```bash
terraform apply
# Review the plan and type 'yes' to confirm
```

### Step 6: Access Application
Once deployed, get the ALB DNS name:
```bash
terraform output alb_dns_name
```

Visit `http://<alb-dns-name>` in your browser.

### Step 7: Access EC2 Instances (Optional)
```bash
# List available instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]'

# Connect via Session Manager
aws ssm start-session --target <instance-id>
```

## Cost Estimation

Monthly costs (approximate, varies by region):
- **VPC:** ~$32 (2 NAT Gateways @ $32/month each)
- **ALB:** ~$16 (ALB + data processing)
- **EC2:** ~$60-120 (t3.medium × 2 instances)
- **RDS:** ~$40-80 (db.t3.micro Multi-AZ)
- **Data Transfer:** $0-20 (depends on traffic)
- **CloudWatch:** ~$10 (logs + alarms)

**Total: ~$160-280/month**

### Cost Optimization Tips
1. **Use Reserved Instances:** 30% savings for 1-year commitments
2. **Right-size instances:** Monitor and adjust instance types
3. **Set ASG limits:** Prevent runaway scaling costs
4. **Database optimization:** Use storage auto-scaling carefully
5. **NAT Gateway alternatives:** Use NAT instances for lower traffic
6. **CloudWatch logs retention:** Set retention to 7-14 days

## Traffic Flow

1. **User Request:** User accesses ALB DNS name
2. **ALB Processing:** Load Balancer distributes traffic to healthy EC2 instances
3. **Application Layer:** EC2 instance processes request, queries database
4. **Database Layer:** RDS stores/retrieves data, syncs to standby in AZ2
5. **Response:** EC2 returns response through ALB back to user
6. **Logging:** Application logs sent to CloudWatch Logs

## Monitoring & Alerts

### Key Metrics to Monitor
- **ALB Target Health:** Healthy vs unhealthy instances
- **EC2 CPU Utilization:** Should stay under 70%
- **RDS Database Connections:** Should not exceed limits
- **RDS Free Storage:** Alert if below 1GB
- **ASG Desired vs Running:** Ensure instances are launching

### Access CloudWatch Console
```bash
# View logs
aws logs describe-log-groups
aws logs tail /aws/ec2/3-tier-web-app --follow

# View alarms
aws cloudwatch describe-alarms
```

## Disaster Recovery

### Failover Scenarios
1. **EC2 Instance Failure:**
   - ASG detects unhealthy instance
   - Launches replacement in 2-3 minutes
   - ALB removes from target group
   
2. **Availability Zone Failure:**
   - ASG launches instance in other AZ
   - RDS auto-failover to standby in other AZ
   - Service remains operational

3. **Database Failure:**
   - Automatic failover to RDS standby (1-2 minutes)
   - No manual intervention needed
   - Backups retain 7 days of recovery

## Security Best Practices

- ✅ **No SSH Access:** All access via Session Manager
- ✅ **Least Privilege IAM:** EC2 role only allows necessary AWS actions
- ✅ **Database Encryption:** KMS encryption at rest
- ✅ **Security Groups:** Explicit allow rules, no unnecessary open ports
- ✅ **Backups Encrypted:** RDS backups are encrypted
- ✅ **No Public Database:** RDS in private subnet, not publicly accessible
- ✅ **Monitoring:** All resources logged and monitored

## Cleanup

To avoid ongoing costs, destroy the infrastructure:

```bash
terraform destroy
# Review what will be deleted
# Type 'yes' to confirm
```

## Design Decisions

### Why Multi-AZ?
- **Availability:** One AZ failure doesn't impact application
- **Compliance:** Many regulations require multi-AZ
- **Zero downtime:** Updates don't require service interruption

### Why Application Load Balancer?
- **Layer 7 (Application):** Can route based on URLs, hostnames, HTTP headers
- **Better than NLB:** Suitable for HTTP/HTTPS traffic
- **Health checks:** Automatic detection of unhealthy instances

### Why Auto Scaling Group?
- **Automatic scaling:** Handles traffic spikes
- **Cost efficient:** Scales down during low traffic
- **Self-healing:** Replaces failed instances automatically

### Why RDS Multi-AZ?
- **Automatic failover:** No manual intervention
- **Synchronous replication:** No data loss
- **Production standard:** Used by Fortune 500 companies

### Why Private Subnets for EC2 and RDS?
- **Security:** No direct internet access
- **NAT Gateway for outbound:** Controlled internet access
- **Reduced attack surface:** Smaller blast radius

## Troubleshooting

### Instances not launching?
```bash
# Check ASG activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name 3-tier-web-app-asg

# Check launch template
aws ec2 describe-launch-templates
```

### Cannot connect to database?
```bash
# Check RDS endpoint
terraform output rds_endpoint

# Verify security group
aws ec2 describe-security-groups --filters Name=group-name,Values=*rds*

# Test connectivity from EC2
aws ssm start-session --target <instance-id>
# Inside session: nc -zv <rds-endpoint> 3306
```

### High CPU on instances?
```bash
# Scale up instance type in variables.tf
instance_type = "t3.large"

# Or increase ASG capacity
asg_desired_capacity = 4

# Reapply
terraform apply
```

## Next Steps

1. **Test Application:** Deploy sample application to EC2
2. **Setup CI/CD:** Use Project 5 (CodePipeline) to automate deployments
3. **Add HTTPS:** Use ACM certificate with ALB listener
4. **Database Migration:** Migrate production data to RDS
5. **Performance Testing:** Load test to optimize instance types
6. **Cost Optimization:** Use AWS Cost Explorer to identify savings

## Additional Resources

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/)
- [EC2 Auto Scaling Guide](https://docs.aws.amazon.com/autoscaling/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [VPC Design Guide](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Networking.html)

## Support

For issues or questions:
1. Check AWS CloudWatch Logs
2. Review Terraform state: `terraform state list`
3. Check AWS CloudFormation events (if using)
4. Review security group rules and NACLs
5. Verify IAM permissions

---

**Version:** 1.0  
**Last Updated:** 2024  
**Terraform Version:** >= 1.0  
**AWS Provider:** >= 5.0
