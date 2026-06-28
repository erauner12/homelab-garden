.PHONY: doctor kind-up kind-status static schema contracts local-validate check kind-down

doctor:
	bash ./scripts/doctor.sh

kind-up:
	./scripts/kind-up.sh

kind-status:
	./scripts/kind-status.sh

static:
	./validation/static.sh

schema:
	./validation/schema.sh

contracts:
	go test ./tests/contracts

local-validate:
	garden workflow local-validate --env local

check:
	$(MAKE) doctor
	$(MAKE) static
	$(MAKE) schema
	$(MAKE) contracts
	garden get config --env local --resolve=partial
	$(MAKE) local-validate

kind-down:
	./scripts/kind-down.sh
