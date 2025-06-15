# DevOpsTP Project: AWS Infrastructure with Terraform

## Project Overview

This project provides a comprehensive Terraform configuration to deploy a robust and scalable infrastructure on Amazon Web Services (AWS). It sets up a multi-tier architecture including a Virtual Private Cloud (VPC), public and private subnets, an Application Load Balancer (ALB), Auto Scaling Groups (ASGs) for a React application and a Business Intelligence (BI) tool (Metabase), Amazon RDS instances for MySQL and PostgreSQL databases, and Route53 DNS records for domain management. The React application and Metabase are deployed as Docker containers on EC2 instances managed by ASGs, with Nginx acting as a reverse proxy.

This infrastructure is designed for high availability and scalability, leveraging AWS best practices for secure and efficient cloud deployments. It includes automated scaling policies based on CPU utilization and integrates with AWS Certificate Manager (ACM) for SSL/TLS encryption.

## Prerequisites

Before you begin, ensure you have the following:

*   **AWS Account**: An active AWS account with appropriate permissions to create and manage EC2, VPC, RDS, ALB, Route53, and ACM resources.
*   **AWS CLI**: Configured with credentials for your AWS account. You can install it by following the official AWS documentation.
*   **Terraform**: Version `~> 1.0` or later installed on your local machine. Download and install Terraform from the official HashiCorp website.
*   **Registered Domain Name**: A domain name registered with AWS Route53. This project assumes you have an existing hosted zone in Route53 for your domain, which will be used to create subdomains for the React app and BI tool.
*   **SSH Key Pair**: An AWS EC2 key pair in the region where you plan to deploy the infrastructure. The name of this key pair will be used in the `terraform.tfvars` file.




## Project Structure

The project is organized into several Terraform configuration files, each responsible for a specific part of the AWS infrastructure:

*   `main.tf`: Defines the core AWS infrastructure, including the VPC, public and private subnets, Internet Gateway, and route tables. This file establishes the network foundation for the entire deployment.

*   `variables.tf`: Contains all the input variables for the Terraform configuration, such as AWS region, project name, environment, CIDR blocks for VPC and subnets, instance types, Auto Scaling Group sizes, database credentials, and domain name. This allows for easy customization of the deployment.

*   `outputs.tf`: Defines the output values from the Terraform deployment, such as ALB DNS names, RDS endpoints, and other useful information that can be used to access the deployed resources.

*   `ec2.tf`: Configures the EC2 instances, Launch Templates, and Auto Scaling Groups for both the React application and the BI tool. It also includes CloudWatch alarms for CPU utilization to manage auto-scaling policies.

*   `alb.tf`: Sets up the Application Load Balancer (ALB), HTTP and HTTPS listeners, and listener rules to route traffic to the React application and BI tool. It handles SSL/TLS termination and redirects HTTP traffic to HTTPS.

*   `rds.tf`: Defines the Amazon RDS instances for MySQL and PostgreSQL databases, including their configurations, security groups, and subnet groups. This file ensures persistent storage for the applications.

*   `route53.tf`: Manages Route53 DNS records for the application and BI tool subdomains, pointing them to the ALB. It also handles the AWS Certificate Manager (ACM) certificate creation and validation for SSL/TLS.

*   `security_groups.tf`: Defines the security groups for various components, including EC2 instances, ALB, and RDS databases, controlling inbound and outbound network traffic to ensure secure communication.

*   `target_groups.tf`: Configures the ALB target groups for the React application and BI tool, which are used to register and manage the EC2 instances within the Auto Scaling Groups.

*   `terraform.tfvars`: A file to provide values for the variables defined in `variables.tf`. This file should be customized with your specific AWS details and sensitive information.

*   `Dockerfile-app`: A Dockerfile used to build the Docker image for the React application. This file is referenced by `userapp_data.sh` to containerize the React app.

*   `userapp_data.sh`: A shell script executed on the React application EC2 instances during launch. It installs Docker, Nginx, clones the React app repository, builds the Docker image, runs the container, and configures Nginx as a reverse proxy.

*   `userbi_data.sh`: A shell script executed on the BI tool EC2 instances during launch. It installs Docker, Nginx, sets up swap space, pulls and runs the Metabase Docker container, and configures Nginx as a reverse proxy for Metabase.




## Setup Instructions

Follow these steps to deploy the AWS infrastructure using Terraform:

### 1. Configure `terraform.tfvars`

Before running Terraform, you need to configure the `terraform.tfvars` file with your specific AWS details. This file provides values for the variables defined in `variables.tf`.

Open the `terraform.tfvars` file and update the following variables:

*   `aws_region`: Your desired AWS region (e.g., `us-east-1`, `ap-southeast-1`).
*   `project_name`: A unique name for your project (e.g., `my-devops-project`).
*   `environment`: The deployment environment (e.g., `dev`, `staging`, `prod`).
*   `vpc_cidr`: The CIDR block for your VPC (default is `10.0.0.0/16`).
*   `public_subnet_cidrs`: A list of CIDR blocks for your public subnets (default `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`). Ensure these are within your `vpc_cidr`.
*   `private_subnet_cidrs`: A list of CIDR blocks for your private subnets (default `["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]`). Ensure these are within your `vpc_cidr`.
*   `instance_type`: The EC2 instance type for your application and BI tool (default is `t3.micro`).
*   `min_size_app`, `desired_capacity_app`, `max_size_app`: Auto Scaling Group sizes for the React application.
*   `min_size_bi`, `desired_capacity_bi`, `max_size_bi`: Auto Scaling Group sizes for the BI tool.
*   `key_pair_name`: The name of your existing AWS EC2 key pair. This is crucial for SSH access to your EC2 instances.
*   `domain_name`: Your registered domain name in Route53 (e.g., `example.com`). This will be used to create subdomains like `haseeb-app.example.com` and `haseeb-bi.example.com`.
*   `db_username`: The master username for your RDS databases (default is `admin`).
*   `db_password`: The master password for your RDS databases. **Ensure this is a strong, secure password.**
*   `mysql_db_name`: The name for your MySQL database (default is `mysqlbidb`).
*   `postgres_db_name`: The name for your PostgreSQL database (default is `psqlbidb`).
*   `db_instance_class`: The RDS instance class (default is `db.t3.micro`).
*   `allocated_storage`: The allocated storage in GB for your RDS databases (default is `20`).
*   `backup_retention_period`: The backup retention period in days for RDS (default is `7`).
*   `multi_az`: Set to `true` to enable Multi-AZ deployment for RDS for high availability (default is `false`).
*   `enable_deletion_protection`: Set to `true` to enable deletion protection for RDS instances (default is `false`).

Example `terraform.tfvars`:

```terraform
aws_region                 = "ap-southeast-1"
project_name               = "my-devops-project"
environment                = "dev"
vpc_cidr                   = "10.0.0.0/16"
public_subnet_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs       = ["10.0.10.0/24", "10.0.20.0/24"]
instance_type              = "t3.micro"
min_size_app               = 2
desired_capacity_app       = 2
max_size_app               = 3
min_size_bi                = 1
desired_capacity_bi        = 1
max_size_bi                = 1
key_pair_name              = "my-ec2-keypair"
domain_name                = "example.com"
db_username                = "admin"
db_password                = "YourStrongDBPassword!"
mysql_db_name              = "myreactdb"
postgres_db_name           = "mybidb"
db_instance_class          = "db.t3.micro"
allocated_storage          = 20
backup_retention_period    = 7
multi_az                   = false
enable_deletion_protection = false
```

### 2. Initialize Terraform

Navigate to the project directory in your terminal and initialize Terraform. This command downloads the necessary providers and modules.

```bash
cd /path/to/DevOpsTP
terraform init
```

### 3. Plan the Deployment

Review the execution plan to see what actions Terraform will perform. This step is crucial to ensure that the infrastructure changes align with your expectations.

```bash
terraform plan
```

### 4. Apply the Deployment

If the plan looks good, apply the changes to deploy the infrastructure to your AWS account. Type `yes` when prompted to confirm the deployment.

```bash
terraform apply
```

This process may take several minutes as AWS resources are provisioned.

### 5. Access the Applications

Once the `terraform apply` command completes successfully, Terraform will output the DNS names for your deployed applications. You can find these in the `outputs.tf` file or in the terminal output after `terraform apply`.

*   **React Application**: Access via `https://haseeb-app.<your-domain-name>`
*   **BI Tool (Metabase)**: Access via `https://haseeb-bi.<your-domain-name>`

**Note**: It may take a few minutes for the DNS changes to propagate and for the applications to become fully accessible after the Terraform apply completes.

## Cleanup

To destroy the deployed infrastructure and avoid incurring further AWS costs, run the following command from the project directory:

```bash
terraform destroy
```

Type `yes` when prompted to confirm the destruction of resources.
