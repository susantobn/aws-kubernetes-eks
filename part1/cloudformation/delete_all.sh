#!/bin/bash
# authors: susanto.b.n@gmail.com
# Run All CloudFormation Delete Stack for IAM, VPC, Bastion and EKS Cluster Templates


##################################### Functions Definitions
function usage() {
    echo "usage: $0 [options]"
    echo "Run All CloudFormation Delete Stack for IAM, VPC, Bastion and EKS Cluster Templates"
    echo "by default are using AWS CLI default profile & region, otherwise please provide profile and/or region option"
    echo " "
    echo -e "options:"
    echo -e "-h, --help \t Show options for this script"
    echo -e "-p, --profile \t AWS CLI profile"
    echo -e "-r, --region \t AWS Region"
    echo -e "--iam-stack \t IAM CloudFormation's Stack Name ('Iam-Stack' by default)"
    echo -e "--vpc-stack \t VPC CloudFormation's Stack Name ('Vpc-Stack' by default)"
    echo -e "--bastion-stack \t Bastion CloudFormation's Stack Name ('Vpc-Bastion-Stack' by default)"
    echo -e "--eks-stack \t EKS CloudFormation's Stack Name ('Vpc-Eks1-Stack' by default)"
}

function aws_get_identity() {
  USER_ARN=($(eval "aws " $PROFILE_PARAM " " $REGION_PARAM " sts get-caller-identity --query 'Arn' --output text"))
  if [[ $USER_ARN == "arn:aws:iam::"* ]]; then
    echo "User : $USER_ARN"
    export USER_ARN
  else
    exit;
  fi
}

function aws_delete_stack() {
  if [ "$#" -le "0" ]; then echo "error: aws_delete_stack Stack Name are Required"; exit 1; fi

  local STACK_NAME=$1
  local PARAMS=$2
  
  local STACK_DELETE=($(eval "aws " $PROFILE_PARAM " " $REGION_PARAM " cloudformation delete-stack --stack-name " $STACK_NAME " " $PARAMS))
  
  if [[ -z "$STACK_DELETE" ]] ; then echo "$STACK_NAME Delete Failed"; exit 1; fi
  echo "Deleting $STACK_NAME"
}

function aws_wait_delete_stack() {
  if [ "$#" -le "0" ]; then echo "error: aws_delete_stack Stack Name & Template are Required"; exit 1; fi

  local STACK_NAME=$1
  
  STACK_STATUS=$(eval "aws " $PROFILE_PARAM " " $REGION_PARAM " cloudformation wait stack-delete-complete --stack-name " $STACK_NAME)
  
  if [[ $STACK_STATUS == "" ]]; then
      echo "$STACK_NAME Deleted"
  else
      exit 1
  fi
}

function aws_delete_stack_IAM() {
  aws_delete_stack $IAM_STACK "--capabilities CAPABILITY_NAMED_IAM"
}

function aws_delete_stack_VPC() {
  aws_delete_stack $VPC_STACK
}

function aws_delete_stack_Bastion() {
  aws_delete_stack $BASTION_STACK
}

function aws_delete_stack_EKS() {
  aws_delete_stack $EKS_STACK
}

##################################### End Function Definitions

NARGS=$#

# extract options and their arguments into variables.
while true; do
    case "$1" in
        -h | --help)
            usage
            exit 1
            ;;
        -p | --profile)
            PROFILE="$2"
            PROFILE_PARAM="--profile $PROFILE"
            shift 2
            ;;
        -r | --region)
            REGION="$2";
			REGION_PARAM="--region $REGION"
            shift 2
            ;;
        --iam-stack)
            IAM_STACK="$2";
            shift 2
            ;;
        --vpc-stack)
            VPC_STACK="$2";
            shift 2
            ;;
        --bastion-stack)
            BASTION_STACK="$2";
            shift 2
            ;;
        --eks-stack)
            EKS_STACK="$2";
            shift 2
            ;;
        --)
            break
            ;;
        *)
            break
            ;;
    esac
done

if [[ $NARGS == 0 ]] ; then echo " "; fi

if [[ -z "$IAM_STACK" ]] ; then IAM_STACK="Iam-Stack"; fi
if [[ -z "$VPC_STACK" ]] ; then VPC_STACK="Vpc-Stack"; fi
if [[ -z "$BASTION_STACK" ]] ; then BASTION_STACK="Vpc-Bastion-Stack"; fi
if [[ -z "$EKS_STACK" ]] ; then EKS_STACK="Vpc-Eks1-Stack"; fi

aws_get_identity

echo "IAM Stack Name : $IAM_STACK"
echo "VPC Stack Name : $VPC_STACK"
echo "Bastion Stack Name : $BASTION_STACK"
echo "EKS Stack Name : $EKS_STACK"

aws_delete_stack_Bastion
aws_delete_stack_EKS

aws_wait_delete_stack $BASTION_STACK
aws_wait_delete_stack $EKS_STACK

aws_delete_stack_IAM
aws_delete_stack_VPC
  
aws_wait_delete_stack $IAM_STACK
aws_wait_delete_stack $VPC_STACK
  
exit;