.DEFAULT_GOAL := test

KUBE_VERSION := v1.33.4
GO_VERSION_KUBE := 1.24

ETCD_IMAGE := gcr.io/etcd-development/etcd
ETCD_VERSION := v3.6.4

SETCD_IMAGE := ghcr.io/setcd-io/server
SETCD_VERSION := etcd-3.6

SETCD := true

ifeq ($(SETCD),true)
	override ETCD_IMAGE := $(SETCD_IMAGE)
	override ETCD_VERSION := $(SETCD_VERSION)
endif

_preflight:
	@which docker >/dev/null 2>&1 || (echo "docker not found in PATH"; exit 1)
	@docker --version >/dev/null 2>&1 || (echo "docker not working"; exit 1)
	@docker compose version >/dev/null 2>&1 || (echo "docker compose not found"; exit 1)
	@which kubectl >/dev/null || { echo "kubectl not found.\n\tInstall kubectl first."; exit 1; }
	@kubectl krew version >/dev/null 2>&1 || { echo "krew not found.\n\tInstall with: brew install krew"; exit 1; }
	@kubectl krew list | grep -q kuttl || { echo "kuttl plugin not found.\n\tInstall with: kubectl krew install kuttl"; exit 1; }

up:
	@KUBE_VERSION=$(KUBE_VERSION) GO_VERSION_KUBE=$(GO_VERSION_KUBE) ETCD_IMAGE=$(ETCD_IMAGE) ETCD_VERSION=$(ETCD_VERSION) \
	docker compose -f tests/docker-compose.yml up --build --pull always --force-recreate --remove-orphans -d

stats:
	@docker compose -f tests/docker-compose.yml stats

down:
	@docker compose -f tests/docker-compose.yml down --remove-orphans

clean:
	@docker compose -f tests/docker-compose.yml down --volumes --remove-orphans

logs:
	@docker compose -f tests/docker-compose.yml logs -f

_export:
	@docker compose -f tests/docker-compose.yml logs -t --no-color > tests/logs-$(shell date +%Y%m%d-%H%M%S).out 2>&1 || true

_test: export KUBECONFIG=tests/kubeconfig
_test:
	@echo "Running kuttl..."
	@kubectl kuttl test tests --config tests/config.yaml
	@echo "kuttl completed."
	@echo "\nNodes:"
	@kubectl get nodes || true
	@echo "\nPods:"
	@kubectl get pods --all-namespaces || true

test: _preflight down up _test
	@echo "\nTests completed."
	@echo "\nCollecting logs..."
	@$(MAKE) _export
	@echo "Logs collected in tests/logs-*.out"
	@echo "\nTearing down test environment..."
	@$(MAKE) down
	@echo "Test environment torn down."
