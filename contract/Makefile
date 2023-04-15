.PHONY: all init test

all: init test

init:
	@forge install openzeppelin/openzeppelin-contracts@v4.8.1 --no-commit
	@forge remappings

test:
	@forge test -vvv --gas-report


deploy:
	@forge script script/RadioPermissionController.s.sol:RadioPermissionControllerScript --fork-url  ${RINKEBY_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv
