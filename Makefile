.PHONY: doctor kind-up kind-status release-intent static schema contracts demo-api-test local-validate policy-validate check kind-down

doctor:
	bash ./scripts/doctor.sh

kind-up:
	./scripts/kind-up.sh

kind-status:
	./scripts/kind-status.sh

release-intent:
	python3 ./validation/release_intent.py

static:
	./validation/static.sh

schema:
	./validation/schema.sh

contracts:
	go test ./tests/contracts

demo-api-test:
	cd k8s/apps/workloads/demo-api && uv run pytest

local-validate:
	garden workflow local-validate --env local

policy-validate:
	garden workflow policy-validate --env local

check:
	$(MAKE) doctor
	$(MAKE) release-intent
	$(MAKE) static
	$(MAKE) schema
	$(MAKE) contracts
	garden get config --env local --resolve=partial
	$(MAKE) local-validate

kind-down:
	./scripts/kind-down.sh
