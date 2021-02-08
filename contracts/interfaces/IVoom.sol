// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVoom {

    function deposit(uint256 _amountUser, uint256 _amountPromise, uint256 _amountBonus, uint256 _tokensLP, uint256 _pid, address _user) external;

    function claim(uint256 _amountGain, uint256 _amountGainNetwork, bool _check, uint256 _pid, address _user) external;

    function withdraw(uint256 _pid, address _user) external;

}