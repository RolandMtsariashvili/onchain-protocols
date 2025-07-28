// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Blackjack is ReentrancyGuard {
    enum GameStatus {
        Waiting,
        PlayerTurn,
        DealerTurn,
        Finished
    }

    struct Hand {
        uint8[] cards;
        bool stood;
        bool busted;
    }

    struct Game {
        address player;
        Hand playerHand;
        Hand dealerHand;
        GameStatus status;
        uint lastActionBlock;
        uint betAmount;
    }

    uint public nextGameId;
    mapping(uint => Game) public games;

    event GameStarted(uint gameId, address player, uint betAmount);

    // This will use Chainlink VRF ( in separate repo where testnet will be introduced)
    function _dealCard(
        address player,
        uint salt
    ) internal view returns (uint8) {
        uint rand = uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    player,
                    salt
                )
            )
        );
        uint8[13] memory distribution = [
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            10,
            10,
            10,
            11
        ];
        uint8 index = uint8(rand % 13);
        return distribution[index];
    }

    function startGame() external payable {
        nextGameId++;

        uint8 card1 = _dealCard(msg.sender, 1);
        uint8 card2 = _dealCard(msg.sender, 2);

        uint8 dealerCard = _dealCard(msg.sender, 3);

        games[nextGameId] = Game({
            player: msg.sender,
            playerHand: Hand({
                cards: new uint8[](0),
                stood: false,
                busted: false
            }),
            dealerHand: Hand({
                cards: new uint8[](0),
                stood: false,
                busted: false
            }),
            status: GameStatus.PlayerTurn,
            lastActionBlock: block.number,
            betAmount: msg.value
        });

        games[nextGameId].playerHand.cards.push(card1);
        games[nextGameId].playerHand.cards.push(card2);
        games[nextGameId].dealerHand.cards.push(dealerCard);

        emit GameStarted(nextGameId, msg.sender, msg.value);
    }
}
