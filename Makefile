.PHONY: kind-up kind-status static contracts local-validate check kind-down

kind-up:
	./scripts/kind-up.sh

kind-status:
	./scripts/kind-status.sh

static:
	./validation/static.sh

contracts:
	go test ./tests/contracts

local-validate:
	garden workflow local-validate --env local

check:
	$(MAKE) static
	$(MAKE) contracts
	garden get config --env local --resolve=partial
	$(MAKE) local-validate

kind-down:
	./scripts/kind-down.sh
