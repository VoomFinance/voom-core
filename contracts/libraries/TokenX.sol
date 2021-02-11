// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

contract TokenX is BEP20('USDT-TEST', 'USDT-TEST') {

    constructor() public {
        _mint(msg.sender, 100000000 ether);
    }

}