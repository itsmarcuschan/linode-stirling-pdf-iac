init:
	terraform init

validate:
	terraform validate

plan:
	terraform plan

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

deploy: validate plan apply

redeploy: destroy deploy
