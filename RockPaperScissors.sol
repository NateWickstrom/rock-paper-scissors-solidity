pragma solidity ^0.4.24;

import "./GameTokens.sol";
import "./RockPaperScissorsUtils.sol";

/**
 * @title RockPaperScissors
 *
 * @dev The RockPaperScissors contract allows two people to player the game
 * and make bets on it.
 */
contract RockPaperScissors is GameTokens {

    using RockPaperScissorsUtils for uint;

    enum GameStatus {
        // one player (alpha) has create the game
        CREATED,
        // both players have submitted (encrypted) moves
        MOVED,
        // both players have decoded their moves (and the game is over)
        REVELED,
        // game is over and fund have been transfered
        ENDED
    }

    struct Player {
        address id;
        bytes32 encryptedMove;
        uint move;
    }

    struct Game {
        Player alpha;
        Player omega;
        uint funds;
        GameStatus status;
    }

    event LogGameCreated(uint indexed gameId, address indexed player, uint ante, bytes32 encryptedMove);
    event LogGameJoined(uint indexed gameId, address indexed player, bytes32 encryptedMove);
    event LogMoveRevealed(uint indexed gameId, address indexed player, string password, uint move);
    event LogLeaveGame(uint indexed gameId);
    event LogGameClosed(uint indexed gameId);

    mapping(uint => Game) public games;
    mapping(bytes32 => bool) public usedEncryptedMove;

    uint nextGameId;

    /**
    * @dev create a new Rock/Paper/Scissors game and transfer the senders ante
    * to the pot.
    *
    * @param ante           amount of tokens each player provide to join th game.
    * @param encryptedMove  encriped hash for moved.
    *
    * @return gameId        the id player use to identify a specific game.
    */
    function createGame(uint ante, bytes32 encryptedMove) public returns(uint gameId) {
        require(ante >= 0, "Ante must not be negative");
        require(usedEncryptedMove != bytes32(0), "Encrypted move must not be 0x0");
        require(!usedEncryptedMove[encryptedMove], "Encrypted move already used");
        require(balances[msg.sender] >= ante, "Not enough tokens for ante");

        // create a new game
        uint currentGameId = nextGameId;
        Game storage game = games[currentGameId];
        nextGameId++;
        game.status = GameStatus.CREATED;

        // add the sender to the game
        usedEncryptedMove[promise] = true;
        game.alpha.id = msg.sender;
        game.alpha.encryptedMove = encryptedMove;

        // transfer funds to game account
        balances[msg.sender] -= ante;
        game.funds += ante;

        emit LogGameCreated(currentGameId, msg.sender, ante, encryptedMove);

        return currentGameId;
    }

    /**
    * @dev join a new Rock/Paper/Scissors game and transfer the senders ante
    * to the pot.
    *
    * @param gameId         the id player use to identify a specific game.
    * @param encryptedMove  encriped hash for moved.
    */
    function joinGame(uint gameId, bytes32 encryptedMove) public {
        Game storage game = games[gameId];

        require(usedEncryptedMove != bytes32(0), "Encrypted move must not be 0x0");
        require(!usedEncryptedMove[encryptedMove], "Encrypted move already used");
        require(balances[msg.sender] >= game.funds, "Not enough tokens for ante");
        require(game.status == GameStatus.CREATED, "moves are not permitted");
        require(game.alpha.id != msg.sender, "Stop playing with yourself");

        // add the sender to the game
        usedEncryptedMove[encryptedMove] = true;
        game.omega.id = msg.sender;
        game.omega.promise = promise;

        // transfer funds to game account
        balances[msg.sender] -= game.funds;
        game.funds += game.funds;

        // update game state
        game.status = GameStatus.MOVED;

        emit LogGameJoined(gameId, msg.sender, promise);
    }

    /**
    * @dev reveal a players move in a Rock/Paper/Scissors game.
    *
    * @param gameId         the id player use to identify a specific game.
    * @param password       password used to decript the encoded move into the decodedMove.
    * @param decodedMove    unencrypted move used to verify.
    */
    function revealMove(uint gameId, string password, uint decodedMove) public returns(bool done) {
        Game storage game = games[gameId];

        require(decodedMove.isValid(), "Not a valid move");
        require(game.status == GameStatus.MOVED, "you cant reveal moves in this state");
        require(game.alpha.id == msg.sender
            || game.omega.id == msg.sender, "Only joined players can do this");

        bytes32 promise;

        if (game.alpha.id == msg.sender) {
            promise = game.alpha.promise;
            game.alpha.move = decodedMove;
        } else {
            promise = game.omega.promise;
            game.omega.move = decodedMove;
        }

        require(promise == decode(msg.sender, password, decodedMove), "Password is incorrect");

        emit LogMoveRevealed(gameId, msg.sender, password, decodedMove);

        if (game.alpha.move.isValid() && game.alpha.move.isValid()) {
            // update game state
            game.status = GameStatus.REVELED;
            return true;
        }
        return false;
    }

    /**
    * @dev Close the game by transfering winnings to appropriate players.
    *
    * @param gameId     the id player use to identify a specific game.
    */
    function closeGame(uint gameId) public {
        require(games[gameId].status == GameStatus.REVELED, "Not enough players have moved");

        uint alphaMove = games[gameId].alpha.move;
        uint omegaMove = games[gameId].omega.move;
        uint winnings = games[gameId].funds;

        games[gameId].funds = 0;
        games[gameId].status = GameStatus.ENDED;

        emit LogGameClosed(gameId);

        if (alphaMove.isTiedWith(omegaMove)) {
            balances[games[gameId].alpha.id] += winnings / 2;
            balances[games[gameId].omega.id] += winnings / 2;
        } else if (alphaMove.defeats(omegaMove)) {
            balances[games[gameId].alpha.id] += winnings;
        } else /* alphaMove lost */ {
            balances[games[gameId].omega.id] += winnings;
        }
    }

    function decode(address owner, string password, uint decodedMove) public view returns(bytes32) {
        return sha256(abi.encodePacked(address(this), owner, password, decodedMove));
    }
}
