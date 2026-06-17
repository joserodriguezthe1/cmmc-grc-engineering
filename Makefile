# CMMC GRC Engineering — task runner.
# Recipes use POSIX sh; on Windows run via Git Bash (or run the commands directly).
TF_DIR := terraform/environments/dev

.PHONY: help validate fmt oscal-validate status scan evidence plan apply destroy hooks

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

validate: fmt oscal-validate status ## Run all local gates (terraform + OSCAL)
	@cd $(TF_DIR) && terraform init -backend=false >/dev/null && terraform validate

fmt: ## terraform fmt check
	terraform fmt -recursive -check

oscal-validate: ## Validate OSCAL against the official NIST schema
	python scripts/validate_oscal.py

status: ## SSP status roll-up + 110-practice integrity check
	python scripts/status_report.py --check

scan: ## Checkov IaC security scan (triaged via .checkov.yaml)
	checkov -d terraform --config-file .checkov.yaml

evidence: ## Collect a round of AWS evidence (read-only)
	python evidence/automation/collect_evidence.py

plan: ## terraform plan (Free-Tier safe defaults)
	cd $(TF_DIR) && terraform init && terraform plan

apply: ## terraform apply
	cd $(TF_DIR) && terraform apply

destroy: ## terraform destroy (tear down to stop any charges)
	cd $(TF_DIR) && terraform destroy

hooks: ## Install pre-commit hooks
	pre-commit install
