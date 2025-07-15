// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "../../src/erc20_vesting/ERC20Vesting.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "MCK20") {}
    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
}

contract ERC20VestingTest is Test {
    ERC20Vesting vesting;
    MockERC20 token;
    address user = address(1);
    address admin;

    function setUp() public {
        vesting = new ERC20Vesting(address(token));
        token = new MockERC20();
        admin = address(this);

        token.mint(user, 100);
        vm.prank(user);
        token.approve(address(vesting), type(uint).max);
    }
}
