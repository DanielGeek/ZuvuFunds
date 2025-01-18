// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ZuvuFunds {
    address public owner;
    IERC20 public token;  // ERC20 token to be used for fund distribution

    // Events
    event FundsDistributed(address[] recipients, uint256[] amounts);

    // Constructor to set the token
    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // forward_funds function to distribute funds
    function forward_funds(uint256 totalAmount, uint256[] memory splits, address[] memory recipients) public onlyOwner {
        require(splits.length == recipients.length, "Mismatched splits and recipients");
        require(splits.length > 0, "No recipients");
        
        uint256 totalSplit = 0;
        for (uint256 i = 0; i < splits.length; i++) {
            totalSplit += splits[i];
        }
        require(totalSplit == 100, "Total split must equal 100");

        // Distribute funds
        for (uint256 i = 0; i < splits.length; i++) {
            uint256 amountToSend = (totalAmount * splits[i]) / 100;
            require(token.transferFrom(msg.sender, recipients[i], amountToSend), "Transfer failed");
        }

        emit FundsDistributed(recipients, splits);
    }
}