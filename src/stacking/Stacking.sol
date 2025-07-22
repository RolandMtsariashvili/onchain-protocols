// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CloudCoin is ERC20 {
    constructor(address stackingContract) ERC20("CloudCoin", "CCN") {
        _mint(stackingContract, 1_000_000 ether);
    }
}
