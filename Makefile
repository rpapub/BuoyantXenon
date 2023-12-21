SHELL := /bin/bash

run-script:
	@echo "Sourcing .env and running script"
	@set -a; source .env; set +a
	@GITHUB_TOKEN=$$(echo "$${GITHUB_TOKEN}" | tr -d '\n'); export GITHUB_TOKEN
	@./subdir_to_repository.sh
