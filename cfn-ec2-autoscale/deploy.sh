#!/bin/bash

export AWS_PROFILE=of
export AWS_REGION=us-east-1

region="us-east-1"


gum spin --spinner dot --title "Fetching latest Amazon Linux 2023 AMI ID..." -- sleep 5
gum log --time rfc822 --level info "AMI ID: $ami_id"

gum spin --spinner dot --title "CloudFormation CreateStack | my-ec2-asg-stack" -- sleep 6

# Capture the stack creation output as text
stack_output=$(aws cloudformation create-stack --stack-name my-ec2-asg-stack \
  --template-body file://template.yaml \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t3.small \
  --output text)

# Log the stack creation output using gum log
gum log --time rfc822 --level info "Stack creation output:\n$stack_output"

# Function to check the stack deployment status
check_stack_status() {
  local stack_name=$1
  local status
  
  while true; do
    status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query "Stacks[0].StackStatus" --output text)
    
    case $status in
      CREATE_COMPLETE)
        gum log --time rfc822 --level info "Stack $stack_name created successfully"
        break
        ;;
      CREATE_FAILED)
        gum log --time rfc822 --level error "Stack $stack_name creation failed"
        break
        ;;
      DELETE_COMPLETE)
        gum log --time rfc822 --level info "Stack $stack_name deleted successfully"
        break
        ;;
      DELETE_FAILED)
        gum log --time rfc822 --level error "Stack $stack_name deletion failed"
        break
        ;;
      *)
        gum spin --spinner dot --title "Checking stack $stack_name status... $status" -- sleep 5
        ;;
    esac
  done
}

# Call the function to check the stack deployment status
check_stack_status my-ec2-asg-stack
