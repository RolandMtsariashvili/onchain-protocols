// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Blackjack} from "../../src/blackjack/Blackjack.sol";


contract BlackJackScripted is Blackjack {
    uint8[] private scripted;
    uint private nextIdx;


    function loadScript(uint8[] memory cards) external {
        delete scripted;
        for (uint i = 0; i < cards.length; i++) {
            scripted.push(cards[i]);
        }
        nextIdx = 0;
    }

    function _dealCard(address, uint) internal view override returns(uint8) {
        uint idx = nextIdx;
        require(idx < scripted.length, "No more scripted cards");
        return scripted[idx];
    }
}

contract BlackjackTest is Test {
    Blackjack blackjack;
    address player = address(1);
    address dealer = address(2);

    function setUp() public {
        blackjack = new Blackjack();
        vm.deal(player, 100 ether);
        vm.deal(dealer, 100 ether);
    }

    function testStartGame_gameSuccessfullyStarted() public {
        vm.startPrank(player);
        vm.expectEmit(true, true, false, true);
        emit Blackjack.GameStarted(1, player, 50 ether);
        blackjack.startGame{value: 50 ether}();

        Blackjack.Game memory game = blackjack.getGame(1);
        assertEq(game.player, player);
        assertEq(game.betAmount, 50 ether);
        assertEq(
            uint256(game.status),
            uint256(Blackjack.GameStatus.PlayerTurn)
        );
        assertEq(game.lastActionBlock, block.number);

        vm.stopPrank();
    }

    function testPlayerHit_playerHit() public {
        vm.startPrank(player);
        blackjack.startGame{value: 50 ether}();

        vm.expectEmit(true, true, false, false);
        emit Blackjack.PlayerHit(1, player, 4);
        blackjack.playerHit(1);

        Blackjack.Game memory game = blackjack.getGame(1);
        assertEq(game.player, player);
        assertEq(game.betAmount, 50 ether);
        assertEq(
            uint256(game.status),
            uint256(Blackjack.GameStatus.PlayerTurn)
        );
        assertEq(game.lastActionBlock, block.number);
        vm.stopPrank();
    }
}
