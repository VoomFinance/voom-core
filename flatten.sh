#!/usr/bin/env bash

mkdir -p flats
mkdir -p flats
rm -rf flats/*
./node_modules/.bin/truffle-flattener contracts/Voom.sol > flats/Voom.sol