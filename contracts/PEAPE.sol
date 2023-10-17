// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract PEAPE is ERC20 {

    uint256 public MAX_SUPPLY = 10000*1e18;

    constructor() ERC20("PEAPE", "PEAPE") {
        _mint(msg.sender,MAX_SUPPLY);
    }
}