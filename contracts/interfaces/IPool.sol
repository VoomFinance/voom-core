// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPool {

    function pending() external view returns (uint256);

}