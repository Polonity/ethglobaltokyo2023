.PHONY: all init test

all: init test

init:
	forge install openzeppelin/openzeppelin-contracts@v4.8.1 --no-commit
	forge remappings

test:
	forge test -vvv