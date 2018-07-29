pragma solidity ^0.4.24;

library RockPaperScissorsUtils {

    uint constant ROCK = 1;
    uint constant PAPER = 2;
    uint constant SCISSORS = 3;

    function defeats(uint winner, uint looser) internal pure returns(bool) {
        require(isValid(winner), "winner is not a valid move");
        require(isValid(looser), "looser is not a valid move");

        // rock beats scissors
        if (isRock(winner) && isScissor(looser)) return true;
        // scissors beats paper
        if (isScissor(winner) && isPaper(looser)) return true;
        // paper beats rock
        if (isPaper(winner) && isRock(looser)) return true;

        return false;
    }

    function isTiedWith(uint winner, uint looser) internal pure returns(bool) {
        require(isValid(winner), "Winner must be a valid move");

        return winner == looser;
    }

    function isValid(uint move) internal pure returns(bool) {
        return move >= 0 && move <= 2;
    }

    function isRock(uint move) internal pure returns(bool) {
        return move == ROCK;
    }

    function isPaper(uint move) internal pure returns(bool) {
        return move == PAPER;
    }

    function isScissor(uint move) internal pure returns(bool) {
        return move == SCISSORS;
    }

}
