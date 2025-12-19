# ECS Infrastructure with Terraform

This Terraform template creates a production-ready ECS infrastructure following AWS Well-Architected Framework principles and CIS v4 controls.

## Architecture Overview

- **VPC**: Multi-AZ setup with public and private subnets
- **ECS**: Fargate-based container service with autoscaling
- **ALB**: Application Load Balancer with HTTPS and WAF
- **ECR**: Container registry with vulnerability scanning
- **IAM**: Least privilege roles and policies
- **Security**: Encryption at rest and in transit, VPC Flow Logs

## Features




### Security (CIS v4 Compliance)
- ✅ VPC Flow Logs enabled (CIS 3.9)
- ✅ Encryption at rest for all data stores (CIS 3.7)
- ✅ No auto-assign public IPs (CIS 4.9)
- ✅ ECR image scanning enabled (CIS 5.2)
- ✅ Immutable ECR tags (CIS 5.1)
- ✅ ECS tasks in private subnets (CIS 5.3)
- ✅ ALB access logging (CIS 2.6)
- ✅ S3 bucket encryption (CIS 2.1.1)
- ✅ S3 public access blocked (CIS 2.1.5)

### Well-Architected Framework
- **Operational Excellence**: Infrastructure as Code, monitoring
- **Security**: Defense in depth, least privilege access
- **Reliability**: Multi-AZ deployment, auto-scaling, health checks
- **Performance Efficiency**: Right-sizing, auto-scaling policies
- **Cost Optimization**: Resource tagging, lifecycle policies

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. S3 bucket for Terraform state (update backend configuration)
4. Domain name for SSL certificate (optional)

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <repository>
   cd terraform-ecs-infrastructure
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update variables**:
   Edit `terraform.tfvars` with your specific values:
   ```hcl
   project_name = "your-app-name"
   environment  = "dev"
   owner        = "Your Team"
   ```

3. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Module Structure

```
├── main.tf                 # Main configuration
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── terraform.tfvars.example
└── modules/
    ├── vpc/              # VPC and networking
    ├── security/         # Security groups
    ├── iam/             # IAM roles and policies
    ├── ecr/             # Container registry
    ├── alb/             # Application Load Balancer
    └── ecs/             # ECS cluster and service
```

## Configuration

### Right-sizing Guidelines

| Environment | CPU  | Memory | Min Tasks | Max Tasks |
|-------------|------|--------|-----------|-----------|
| Development | 256  | 512    | 1         | 3         |
| Staging     | 512  | 1024   | 2         | 5         |
| Production  | 1024 | 2048   | 3         | 20        |

### Auto-scaling Policies

- **CPU Utilization**: Target 70%
- **Memory Utilization**: Target 80%
- **Scale-out cooldown**: 5 minutes
- **Scale-in cooldown**: 5 minutes

## Security Features

### Encryption
- **EBS**: Encrypted with customer-managed KMS keys
- **S3**: Server-side encryption with KMS
- **ECR**: Repository encryption enabled
- **Secrets Manager**: KMS encryption for secrets
- **CloudWatch Logs**: Encrypted log groups

### Network Security
- Private subnets for ECS tasks
- Security groups with least privilege
- VPC endpoints for AWS services
- WAF protection for ALB

### Access Control
- IAM roles with minimal permissions
- Resource-based policies
- Cross-account access controls

## Monitoring and Logging

- **CloudWatch Container Insights**: Enabled for ECS
- **VPC Flow Logs**: All traffic logged
- **ALB Access Logs**: Stored in S3
- **Application Logs**: Centralized in CloudWatch

## Cost Optimization

- **Fargate Spot**: Consider for non-critical workloads
- **Reserved Capacity**: For predictable workloads
- **Lifecycle Policies**: Automatic cleanup of old resources
- **Resource Tagging**: Cost allocation and tracking

## Deployment Pipeline

1. **Build**: Container image built and scanned
2. **Test**: Security and vulnerability testing
3. **Deploy**: Blue/green deployment with ECS
4. **Monitor**: Health checks and metrics

## Troubleshooting

### Common Issues

1. **Task fails to start**:
   - Check CloudWatch logs: `/ecs/{project-name}-{environment}`
   - Verify ECR permissions
   - Check security group rules

2. **Health check failures**:
   - Verify health check endpoint
   - Check application startup time
   - Review security group ingress rules

3. **Auto-scaling not working**:
   - Check CloudWatch metrics
   - Verify IAM permissions
   - Review scaling policies

## Security Considerations

### Secrets Management
- Use AWS Secrets Manager for sensitive data
- Rotate secrets regularly
- Use IAM roles instead of access keys

### Container Security
- Use minimal base images
- Scan images for vulnerabilities
- Run containers as non-root user
- Keep images updated

### Network Security
- Use private subnets for workloads
- Implement defense in depth
- Monitor network traffic

## Maintenance

### Regular Tasks
- Update container images
- Review and rotate secrets
- Monitor costs and usage
- Update security groups as needed

### Disaster Recovery
- Multi-AZ deployment provides high availability
- Database backups (if applicable)
- Infrastructure as Code enables quick recovery

## Contributing

1. Follow Terraform best practices
2. Update documentation for changes
3. Test in development environment first
4. Use semantic versioning for releases

## Support

For issues and questions:
1. Check CloudWatch logs
2. Review AWS documentation
3. Contact your DevOps team

## License

This project is licensed under the MIT License - see the LICENSE file for details.