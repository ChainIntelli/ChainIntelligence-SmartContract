# ==================== Environment Variables ====================
-include .env

# Foundry Configuration
FOUNDRY_PROFILE ?= default

# Keystore Configuration
KEY_STORE_PATH ?= ./keystore/deployer
KEY_PWD_PATH ?= ./keystore/deployer.password.txt

# Network Configuration
BSC_TEST_RPC_URL ?= https://data-seed-prebsc-1-s1.binance.org:8545

# ==================== Install Dependencies ====================
.PHONY: install
install:
	forge install

.PHONY: update
update:
	forge update

# ==================== Build ====================
.PHONY: build
build:
	forge build

.PHONY: clean
clean:
	forge clean

# ==================== Test Commands ====================
.PHONY: test
test:
	forge test -vvv

.PHONY: test-unit
test-unit:
	forge test --match-path "test/CheckIn.t.sol" -vvv

.PHONY: test-upgrade
test-upgrade:
	forge test --match-path "test/CheckIn.upgrade.t.sol" -vvv

.PHONY: test-gas
test-gas:
	forge test --match-path "test/CheckIn.gas.t.sol" -vvv --gas-report

.PHONY: test-all
test-all:
	forge test -vvv --gas-report

.PHONY: test-coverage
test-coverage:
	forge coverage --report lcov

# ==================== Gas Reports ====================
.PHONY: gas-report
gas-report:
	forge test --gas-report

.PHONY: gas-snapshot
gas-snapshot:
	forge snapshot

.PHONY: gas-snapshot-diff
gas-snapshot-diff:
	forge snapshot --diff

# ==================== Code Quality ====================
.PHONY: fmt
fmt:
	forge fmt

.PHONY: fmt-check
fmt-check:
	forge fmt --check

.PHONY: lint
lint: fmt-check
	forge build --force

# ==================== Keystore Management ====================
.PHONY: create-keystore
create-keystore:
	./script/create-keystore.sh

# ==================== BSC Testnet Deployment ====================
.PHONY: deploy-bsc-test
deploy-bsc-test:
	forge script script/Deploy.s.sol:DeployScript \
		--rpc-url $(BSC_TEST_RPC_URL) \
		--keystore $(KEY_STORE_PATH) \
		--password-file $(KEY_PWD_PATH) \
		--broadcast \
		-vvv

# ==================== Contract Upgrade ====================
.PHONY: upgrade-bsc-test
upgrade-bsc-test:
	forge script script/Upgrade.s.sol:UpgradeScript \
		--rpc-url $(BSC_TEST_RPC_URL) \
		--keystore $(KEY_STORE_PATH) \
		--password-file $(KEY_PWD_PATH) \
		--broadcast \
		-vvv

# ==================== Storage Layout ====================
.PHONY: storage-layout
storage-layout:
	forge inspect src/CheckIn.sol:CheckIn storage-layout --pretty

# ==================== Help ====================
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Install & Build:"
	@echo "  install          - Install dependencies"
	@echo "  build            - Compile contracts"
	@echo "  clean            - Clean build artifacts"
	@echo ""
	@echo "Test:"
	@echo "  test             - Run all tests"
	@echo "  test-unit        - Run unit tests"
	@echo "  test-upgrade     - Run upgrade tests"
	@echo "  test-gas         - Run gas tests (with report)"
	@echo "  test-all         - Run all tests (with gas report)"
	@echo "  test-coverage    - Generate test coverage report"
	@echo ""
	@echo "Gas Analysis:"
	@echo "  gas-report       - Generate gas report"
	@echo "  gas-snapshot     - Generate gas snapshot"
	@echo "  gas-snapshot-diff- Compare gas snapshot diff"
	@echo ""
	@echo "Code Quality:"
	@echo "  fmt              - Format code"
	@echo "  fmt-check        - Check code formatting"
	@echo "  lint             - Lint check"
	@echo ""
	@echo "Keystore:"
	@echo "  create-keystore  - Create encrypted keystore"
	@echo ""
	@echo "Deploy:"
	@echo "  deploy-bsc-test  - Deploy to BSC testnet"
	@echo ""
	@echo "Upgrade:"
	@echo "  upgrade-bsc-test - Upgrade contract on BSC testnet"
	@echo ""
	@echo "Utilities:"
	@echo "  storage-layout   - View storage layout"
