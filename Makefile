SHELL := /bin/bash

setup-tools:
	@uv sync --locked

run-script: setup-tools
	@echo "Sourcing .env and running script"
	@set -a; source .env; set +a
	@GITHUB_TOKEN=$$(echo "$${GITHUB_TOKEN}" | tr -d '\n'); export GITHUB_TOKEN
	@PATH="$$(pwd)/.venv/bin:$$PATH" ./subdir_to_repository.sh
