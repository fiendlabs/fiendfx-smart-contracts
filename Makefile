-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 


help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.0.11 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

coverage :; forge coverage --report debug > coverage-report.txt

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
NETWORK_ARGS_NO_BROADCAST := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY)

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployUSDFFX.s.sol:DeployUSDFFX $(NETWORK_ARGS)

startLocalSepolia:
	anvil --chain-id 1337 --fork-url $(SEPOLIA_RPC_URL)

depositWeth:
	cast send $(WETH_ADDRESS) "deposit()" --value 10.1ether $(NETWORK_ARGS_NO_BROADCAST)

approveWeth:
	cast send $(WETH_ADDRESS) "approve(address,uint256)" $(ENGINE_ADDRESS) 1000000000000000000 $(NETWORK_ARGS_NO_BROADCAST)

mintUsdffx:
	cast send $(ENGINE_ADDRESS) "depositCollateralAndMintUsdffx(address,uint256,uint256)" $(WETH_ADDRESS) 100000000000000000 10000000000000000 $(NETWORK_ARGS_NO_BROADCAST)

redeemCollateral:
	cast send $(ENGINE_ADDRESS) "redeemCollateralForDsc(address,uint256,uint256)" $(WETH_ADDRESS) 100000000000000000 10000000000000000 $(NETWORK_ARGS_NO_BROADCAST)


mintDsc:
	cast send 0x091EA0838eBD5b7ddA2F2A641B068d6D59639b98 "depositCollateralAndMintDsc(address,uint256,uint256)" 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 100000000000000000 10000000000000000 --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80