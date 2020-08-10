# Centralized Logging Pipeline
## Architecture
![output](/output.PNG)

## Environment configuration
### Localstack
```
cd {Project Path}
docker-compose up
```
### Terraform
```
terraform init
terraform workspace new dev
terraform workspace select dev
terraform apply
```
### 개념 검증
#### EC2(Nginx) - Kinesis
