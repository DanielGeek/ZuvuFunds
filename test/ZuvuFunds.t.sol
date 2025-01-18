// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ZuvuFunds.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./mocks/MockERC20.sol";

contract ZuvuFundsTest is Test {
    ZuvuFunds public zugov;
    address public owner;
    address public recipient1;
    address public recipient2;
    address public recipient3;
    MockERC20 public token;

    function setUp() public {
        owner = address(this);
        recipient1 = address(0x1);
        recipient2 = address(0x2);
        recipient3 = address(0x3);
        
        // Deploy a mock ERC20 token
        token = new MockERC20("MockToken", "MTK");
        zugov = new ZuvuFunds(address(token));

        // Mint tokens to owner
        token.mint(owner, 1000 * 10**18);
        
        // Approve ZuvuFunds contract to spend tokens
        token.approve(address(zugov), type(uint256).max);
    }

    function testForwardFunds() public {
        uint256 totalAmount = 1000 * 10**18;
        
        uint256[] memory splits = new uint256[](3);
        splits[0] = 50;
        splits[1] = 30;
        splits[2] = 20;
        
        address[] memory recipients = new address[](3);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;

        // Transfer the funds
        zugov.forward_funds(totalAmount, splits, recipients);

        // Assert the balance of recipients
        assertEq(token.balanceOf(recipient1), (totalAmount * 50) / 100);
        assertEq(token.balanceOf(recipient2), (totalAmount * 30) / 100);
        assertEq(token.balanceOf(recipient3), (totalAmount * 20) / 100);
    }

    function testOnlyOwnerCanDistribute() public {
        uint256 totalAmount = 1000 * 10**18;
        
        uint256[] memory splits = new uint256[](3);
        splits[0] = 50;
        splits[1] = 30;
        splits[2] = 20;
        
        address[] memory recipients = new address[](3);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;

        // Try to call forward_funds from a non-owner address
        vm.prank(address(0x4));
        vm.expectRevert("Not authorized");
        zugov.forward_funds(totalAmount, splits, recipients);
    }
}