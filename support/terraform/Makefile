MAKEFILE_ROOT := $(shell pwd)
TERRAFORM:=$(shell which terraform)
AWS:=$(shell which aws)

ifeq "$(TERRAFORM)" ""
$(error Terraform is not installed on the host. You have made sad, and I am going to my room and will be crying)
endif

ifeq "$(AWS)" ""
$(error awscli is not installed on the host)
endif

.DEFAULT_GOAL := help

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: hallo-welt-plan
hallo-welt-plan: service_vars check_vars tf_plan ## Runs terraform plan for Hallo Welt

.PHONY: hallo-welt-deploy
hallo-welt-deploy: service_vars check_vars tf_apply ## Deploys Hallo Welt service to AWS

.PHONY: service_vars
service_vars:
	$(eval SERVICE_DNS:=$(SERVICE_NAME)-$(subst .,-,$(SERVICE_VERSION)))
	$(eval export MANDATORY_VARS:= \
		AWS_DEFAULT_REGION \
		AWS_KEY_NAME \
		COREOS_AMI_ID \
		VPC_ID \
		VPC_CIDR \
		PUBLIC_SUBNET_IDS \
		PRIVATE_SUBNET_IDS \
		INSTANCE_TYPE \
		PUBLIC_DOMAIN_ZONEID \
		PUBLIC_DOMAIN \
		SERVICE_NAME \
		SERVICE_VERSION \
		SERVICE_PORT \
		SERVICE_ASG_MAX \
		SERVICE_DNS \
		DOCKERHUB_ACCOUNT \
		TERRAFORM_S3_BUCKET)
	$(eval export VAR_LINE:= \
			-var 'aws_region="$(AWS_DEFAULT_REGION)"' \
			-var 'aws_key_name="$(AWS_KEY_NAME)"' \
			-var 'coreos_ami_id="$(COREOS_AMI_ID)"' \
			-var 'instance_type="$(INSTANCE_TYPE)"' \
			-var 'vpc_id="$(VPC_ID)"' \
			-var 'vpc_cidr="$(VPC_CIDR)"' \
			-var 'private_subnet_ids="$(PRIVATE_SUBNET_IDS)"' \
			-var 'public_subnet_ids="$(PUBLIC_SUBNET_IDS)"' \
			-var 'public_domain_zoneid="$(PUBLIC_DOMAIN_ZONEID)"' \
			-var 'public_domain="$(PUBLIC_DOMAIN)"' \
			-var 'service_name="$(SERVICE_NAME)"' \
			-var 'service_version="$(SERVICE_VERSION)"' \
			-var 'service_port="$(SERVICE_PORT)"' \
			-var 'service_asg_max="$(SERVICE_ASG_MAX)"' \
			-var 'service_dns="$(SERVICE_DNS)"' \
			-var 'dockerhub_account="$(DOCKERHUB_ACCOUNT)"')

.PHONY: tf_remote_config
tf_remote_config:
	find $(MAKEFILE_ROOT) -name 'terraform.tfstate' -delete
	$(AWS) s3 ls s3://$(TERRAFORM_S3_BUCKET) > /dev/null 2>&1 \
		|| $(AWS) s3 mb s3://$(TERRAFORM_S3_BUCKET)
	$(TERRAFORM) remote config \
		-backend=s3 \
		-backend-config="bucket=$(TERRAFORM_S3_BUCKET)" \
		-backend-config="key=$(SERVICE_NAME)/$(SERVICE_VERSION)" \
		-backend-config="region=$(AWS_DEFAULT_REGION)"

.PHONY: tf_plan
tf_plan:
	$(TERRAFORM) plan $(VAR_LINE)

.PHONY: tf_apply
tf_apply: tf_validate tf_remote_config
	$(TERRAFORM) apply $(VAR_LINE)

.PHONY: tf_destroy
tf_destroy: tf_validate tf_remote_config
	$(TERRAFORM) destroy -force $(VAR_LINE)

.PHONY: tf_validate
tf_validate:
	$(TERRAFORM) validate $(VAR_LINE)

.PHONY: check_vars
check_vars:
	@echo -e "\033[1;37mChecking all vars for build are sane\033[0m";
	$(foreach A, $(MANDATORY_VARS),                                   \
		$(if $(value $A),, $(error You must pass env var $A to make)) \
	)
	@echo "... build vars are sane."
