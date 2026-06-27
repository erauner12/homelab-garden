.PHONY: kind-up kind-status static local-validate kind-down

kind-up:
	./scripts/kind-up.sh

kind-status:
	./scripts/kind-status.sh

static:
	./validation/static.sh

local-validate:
	garden workflow local-validate --env local

kind-down:
	./scripts/kind-down.sh
