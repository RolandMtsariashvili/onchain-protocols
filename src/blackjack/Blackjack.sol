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

    event GameStarted(uint indexed gameId, address player, uint betAmount);
    event PlayerHit(uint indexed gameId, address player, uint8 card);
    event PlayerStand(uint indexed gameId, address player);
    event DealerHit(uint indexed gameId, address player, uint8 card);
    event GameFinished(
        uint indexed gameId,
        address player,
        uint8 playerTotal,
        uint8 dealerTotal
    );

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

    function _getHandTotal(
        uint8[] memory cards
    ) internal pure returns (uint8 total, bool isSoft) {
        for (uint i = 0; i < cards.length; i++) {
            total += cards[i];
            if (cards[i] == 11) {
                isSoft = true;
            }
        }

        if (isSoft && total > 21) {
            total -= 10;
            isSoft = false;
        }
        return (total, isSoft);
    }

    function _resolveWinner(uint gameId) internal {
        Game storage game = games[gameId];
        address payable player = payable(game.player);

        uint bet = game.betAmount;

        (uint8 playerTotal, ) = _getHandTotal(game.playerHand.cards);
        (uint8 dealerTotal, ) = _getHandTotal(game.dealerHand.cards);

        if (game.playerHand.busted) {} else if (
            game.dealerHand.busted || playerTotal > dealerTotal
        ) {
            player.transfer(bet * 2);
        } else if (playerTotal == dealerTotal) {
            player.transfer(bet);
        }

        game.status = GameStatus.Finished;
        game.betAmount = 0; // Prevent accidental double payout

        emit GameFinished(gameId, game.player, playerTotal, dealerTotal);
    }

    function startGame() external payable nonReentrant {
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(
            games[nextGameId + 1].player == address(0),
            "Game already started"
        );

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

    function playerHit(uint gameId) external nonReentrant {
        Game storage game = games[gameId];
        require(game.status == GameStatus.PlayerTurn, "Not player turn");
        require(!game.playerHand.stood, "Player already stood");
        require(!game.playerHand.busted, "Player already busted");
        require(
            game.lastActionBlock + 10 > block.number,
            "Time limit has passed"
        );

        uint8 card = _dealCard(msg.sender, 4);
        game.playerHand.cards.push(card);

        (uint8 playerTotal, ) = _getHandTotal(game.playerHand.cards);

        if (playerTotal > 21) {
            game.playerHand.busted = true;
            game.status = GameStatus.Finished;
        }

        game.lastActionBlock = block.number;

        emit PlayerHit(gameId, msg.sender, card);
    }

    function playerStand(uint gameId) external nonReentrant {
        Game storage game = games[gameId];
        require(game.status == GameStatus.PlayerTurn, "Not player turn");
        require(!game.playerHand.stood, "Player already stood");
        require(!game.playerHand.busted, "Player already busted");
        require(
            game.lastActionBlock + 10 > block.number,
            "Time limit has passed"
        );

        game.playerHand.stood = true;
        game.status = GameStatus.DealerTurn;
        game.lastActionBlock = block.number;

        emit PlayerStand(gameId, msg.sender);
    }

    function dealerNextMove(uint gameId) external nonReentrant {
        Game storage game = games[gameId];
        require(game.status == GameStatus.DealerTurn, "Not dealer turn");
        require(
            game.lastActionBlock + 10 > block.number,
            "Time limit has passed"
        );
        require(game.player == msg.sender, "Not your game");

        uint8 dealerTotal;
        bool isSoft;

        while (true) {
            if (dealerTotal >= 17 && !(dealerTotal == 17 && isSoft)) {
                break;
            }

            uint8 card = _dealCard(msg.sender, game.dealerHand.cards.length);
            game.dealerHand.cards.push(card);
            emit DealerHit(gameId, game.player, card);

            (dealerTotal, isSoft) = _getHandTotal(game.dealerHand.cards);
        }

        _resolveWinner(gameId);

        game.lastActionBlock = block.number;
    }

    function getGame(uint gameId) external view returns (Game memory) {
        return games[gameId];
    }
}
