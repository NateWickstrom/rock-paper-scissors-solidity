pragma solidity ^0.4.24;

import "./GameTokens.sol";
import "./RockPaperScissorsUtils.sol";

/**
 * @title RockPaperScissors
 *
 * @dev The RockPaperScissors contract allows the owner to deposit funds and the receiver
 * to receive them as long as they supply the correct passcodes.
 */
contract RockPaperScissors is GameTokens {

    using RockPaperScissorsUtils for string;

    uint constant CREATED = 0;
    uint constant JOIN_BY_ONE = 1;
    uint constant JOIN_BY_TWO = 2;
    uint constant MOVE_SUBMITTED_BY_ONE = 3;
    uint constant MOVE_SUBMITTED_BY_TWO = 4;
    uint constant ENDED = 5;

    struct Player {
        address id;
        bytes32 promise;
        string move;
    }

    struct Game {
        Player alpha;
        Player omega;
        uint ante;
        uint funds;
        uint status;
    }

    event LogGameCreated(uint indexed gameId, uint ante);
    event LogGameJoined(uint indexed gameId, uint ante, bytes32 promise);
    event LogMoveCommitted(uint indexed gameId, string password);
    event LogGameClosed(uint indexed gameId);

    mapping(uint => Game) public games;
    mapping(bytes32 => bool) public usedPromises;

    uint nextGameId;

    function createGame(uint ante) public returns(uint gameId) {
        require(ante >= 0, "Ante must be greater than 0");

        uint currentGameId = nextGameId;
        Game storage game = games[currentGameId];
        game.ante = ante;
        nextGameId++;

        emit LogGameCreated(currentGameId, ante);

        return currentGameId;
    }

    function joinGame(uint gameId, uint anti, bytes32 promise) public returns (bool readyToPlay) {
        Game storage game = games[gameId];

        require(game.ante == anti, "Anti is not correct");
        require(promise != bytes32(0), "Promise move must not be 0x0");
        require(!usedPromises[promise], "Promise already used");
        require(game.status < JOIN_BY_TWO, "Too many players");
        require(balances[msg.sender] >= anti, "Not enough tokens for ante");
        require(game.alpha.id != msg.sender, "Player is already enrolled");
        require(game.omega.id != msg.sender, "Player is already enrolled");

        balances[msg.sender] -= anti;
        game.funds += anti;
        game.status++;

        emit LogGameJoined(gameId, anti, promise);

        if (game.alpha.id == address(0)) {
            game.alpha.id = msg.sender;
            game.alpha.promise = promise;
            return false;
        } else {
            game.omega.id = msg.sender;
            game.omega.promise = promise;
            return true;
        }
    }

    function commitMove(uint gameId, string password, string decodedPromise) public returns(bool done) {
        Game storage game = games[gameId];

        require(decodedPromise.isValid(), "Not a valid move");
        require(game.status >= JOIN_BY_TWO, "Not enough players have joined");
        require(game.status < MOVE_SUBMITTED_BY_TWO, "Already submitted moves");
        require(game.alpha.id == msg.sender
            || game.omega.id == msg.sender, "Only joined players can do this");

        bytes32 promise;
        game.status++;

        emit LogMoveCommitted(gameId, password);

        if (game.alpha.id == msg.sender) {
            promise = game.alpha.promise;
            game.alpha.move = decodedPromise;
        } else {
            promise = game.omega.promise;
            game.omega.move = decodedPromise;
        }

        require(promise == decode(msg.sender, password, decodedPromise), "Password is incorrect");
        usedPromises[promise] = true;

        return game.status == MOVE_SUBMITTED_BY_TWO;
    }

    function closeGame(uint gameId) public {
        require(games[gameId].status == MOVE_SUBMITTED_BY_TWO, "Not enough players have moved");

        string storage alphaMove = games[gameId].alpha.move;
        string storage omegaMove = games[gameId].omega.move;
        uint winnings = games[gameId].funds;

        games[gameId].funds = 0;
        games[gameId].status = ENDED;

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

    //TODO allow exiting before match is over, with a potential refund or forfeit of funds

    function decode(address owner, string password, string decodedPromise) public pure returns(bytes32) {
        return sha256(abi.encodePacked(owner, password, decodedPromise));
    }
}
