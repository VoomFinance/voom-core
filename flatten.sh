#!/usr/bin/env bash

mkdir -p flats
mkdir -p flats
rm -rf flats/*
./node_modules/.bin/truffle-flattener contracts/VoomCake.sol > flats/VoomCake.sol
./node_modules/.bin/truffle-flattener contracts/VoomFuel.sol > flats/VoomFuel.sol
./node_modules/.bin/truffle-flattener contracts/VoomCakeUser.sol > flats/VoomCakeUser.sol
./node_modules/.bin/truffle-flattener contracts/VoomFuelUser.sol > flats/VoomFuelUser.sol