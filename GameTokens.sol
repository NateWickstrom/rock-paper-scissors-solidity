pragma solidity ^0.4.24;

/**
 * @title GameTokens
 *
 * @dev The GameTokens contract allows users to deposit and withdraw funds
 * from their game tokens account.
 */
contract GameTokens {

    mapping(address => uint) public balances;

    event LogDeposit(address indexed account, uint funds);
    event LogWithdraw(address indexed account, uint funds);

    /**
    * @dev  The add funds to the sender's account.
    */
    function deposit() public payable {
        require(msg.value > 0, "Insufficient funds");

        balances[msg.sender] = balances[msg.sender] + msg.value;
        emit LogDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw funds from the sender's account.
     */
    function withdraw() public {
        uint balance = balances[msg.sender];

        require(balance > 0, "Insufficient funds");

        balances[msg.sender] = 0;
        emit LogWithdraw(msg.sender, balance);

        require(msg.sender.send(balance), "Failed to transfer funds");
    }

}
