// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ZuvuFunds
/// @notice Handles the distribution of funds according to predefined splits
/// @dev Implements fund distribution with security features and input validation
contract ZuvuFunds is ReentrancyGuard, Ownable {
    IERC20 public token;  // ERC20 token to be used for fund distribution

    /// @notice Emitted when funds are distributed to recipients
    /// @param recipients Array of addresses receiving funds
    /// @param amounts Array of amounts distributed to each recipient
    event FundsDistributed(address[] recipients, uint256[] amounts);

    /// @notice Sets up the contract with the specified token
    /// @param _token Address of the ERC20 token to be used
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    /// @notice Distributes funds according to specified splits
    /// @param totalAmount Total amount of tokens to distribute
    /// @param splits Array of percentage splits (must sum to 100)
    /// @param recipients Array of recipient addresses
    /// @dev Implements reentrancy protection and comprehensive input validation
    function forward_funds(
    uint256 totalAmount,
    uint256[] memory splits,
    address[] memory recipients
) public onlyOwner nonReentrant {

    require(splits.length == recipients.length, "Mismatched splits and recipients");
    require(splits.length > 0, "No recipients");
    require(totalAmount > 0, "Amount must be greater than 0");

    uint256 totalSplit = 0;
    uint256[] memory amounts = new uint256[](splits.length);

    uint256 totalDistributed = 0;
    for (uint256 i = 0; i < splits.length; i++) {
        require(recipients[i] != address(0), "Invalid recipient address");
        require(splits[i] > 0, "Split must be greater than 0");
        
        totalSplit += splits[i];
        uint256 amount = (totalAmount * splits[i]) / 100;
        amounts[i] = amount;
        totalDistributed += amount;
    }

    require(totalSplit == 100, "Total split must equal 100");

    uint256 adjustment = totalAmount - totalDistributed;
    uint256 proportionateAdjustment = adjustment / splits.length;

    for (uint256 i = 0; i < splits.length; i++) {
        amounts[i] += proportionateAdjustment;
    }

    uint256 finalTotalDistributed = 0;
    for (uint256 i = 0; i < amounts.length; i++) {
        finalTotalDistributed += amounts[i];
    }
    require(finalTotalDistributed == totalAmount, "Total distributed amount must match total amount");

    for (uint256 i = 0; i < splits.length; i++) {
        require(
            token.transferFrom(msg.sender, recipients[i], amounts[i]),
            "Transfer failed"
        );
    }

    emit FundsDistributed(recipients, amounts);
}

    /// @notice Allows the owner to recover any ERC20 tokens sent to the contract by mistake
    /// @param tokenAddress Address of the token to recover
    /// @param amount Amount of tokens to recover
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            IERC20(tokenAddress).transfer(owner(), amount),
            "Token recovery failed"
        );
    }
}