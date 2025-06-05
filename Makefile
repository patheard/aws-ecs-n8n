.PHONY: apply localhost localhost_reset plan

apply:
	@terragrunt apply --terragrunt-working-dir terraform/env/staging

localhost:
	@docker compose up

localhost_reset:
	@docker compose down
	@docker rm -f $(docker ps -aq) || true
	@docker rmi -f $(docker images -q) || true
	@docker volume prune -f
	@docker compose up --build

plan: 
	@terragrunt plan --terragrunt-working-dir terraform/env/staging
