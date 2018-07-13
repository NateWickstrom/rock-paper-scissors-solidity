pragma solidity ^0.4.24;

library RockPaperScissorsUtils {

    string constant ROCK = "rock";
    string constant PAPER = "paper";
    string constant SCISSORS = "scissors";

    function defeats(string winner, string looser) internal pure returns(bool) {
        // rock beats scissors
        if (isRock(winner) && isScissor(looser)) return true;
        // scissors beats paper
        if (isScissor(winner) && isPaper(looser)) return true;
        // paper beats rock
        if (isPaper(winner) && isRock(looser)) return true;

        return false;
    }

    function isTiedWith(string winner, string looser) internal pure returns(bool) {
        require(isValid(winner), "Winner must be a valid move");

        return equals(winner, looser);
    }

    function isValid(string move) internal pure returns(bool) {
        return isRock(move) || isPaper(move) || isScissor(move);
    }

    function isRock(string move) internal pure returns(bool) {
        return equals(move, ROCK);
    }

    function isPaper(string move) internal pure returns(bool) {
        return equals(move, PAPER);
    }

    function isScissor(string move) internal pure returns(bool) {
        return equals(move, SCISSORS);
    }

    function equals(string str1, string str2) private pure returns(bool) {
        //return StringUtils.equal(move, SCISSORS);
        return true;
    }
}
