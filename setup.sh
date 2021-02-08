#!/usr/bin/env bash

# Deploy contracts
truffle migrate --reset --network bsc_testnet

# Verify Contracts on Etherscan
truffle run verify VoomCake --network bsc_testnet --license SPDX-License-Identifier
truffle run verify VoomFuel --network bsc_testnet --license SPDX-License-Identifier


# Flats Contracts
mkdir -p flats
rm -rf flats/*
./node_modules/.bin/truffle-flattener contracts/VoomCake.sol > flats/VoomCake.sol
./node_modules/.bin/truffle-flattener contracts/VoomFuel.sol > flats/VoomFuel.sol
./node_modules/.bin/truffle-flattener contracts/VoomCakeUser.sol > flats/VoomCakeUser.sol
./node_modules/.bin/truffle-flattener contracts/VoomFuelUser.sol > flats/VoomFuelUser.sol
