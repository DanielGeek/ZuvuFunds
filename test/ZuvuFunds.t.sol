// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ZuvuFunds.sol";
import "../src/ZuvuGovernance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mocks/MockERC20.sol";

contract ZuvuFundsTest is Test {
    ZuvuFunds public zuvuFunds;
    ZuvuGovernance public zuvuGov;
    address public owner;
    address public recipient1;
    address public recipient2;
    address public recipient3;
    MockERC20 public token;

    // Events to test
    event FundsDistributed(address[] recipients, uint256[] amounts);
    event ProposalCreated(uint256 indexed proposalId, address proposer, uint256 startTime, uint256 endTime);

    function setUp() public {
        owner = address(this);
        recipient1 = address(0x1);
        recipient2 = address(0x2);
        recipient3 = address(0x3);

        // Deploy contracts
        token = new MockERC20("MockToken", "MTK");
        zuvuFunds = new ZuvuFunds(address(token));
        zuvuGov = new ZuvuGovernance(address(token));

        // Setup initial state
        token.mint(owner, 1000 * 10 ** 18);
        token.approve(address(zuvuFunds), type(uint256).max);
        token.approve(address(zuvuGov), type(uint256).max);

        // Fund recipients for voting tests
        token.mint(recipient1, 100 * 10 ** 18);
        token.mint(recipient2, 100 * 10 ** 18);
        token.mint(recipient3, 100 * 10 ** 18);
    }

    // ZuvuFunds Tests
    // This test is designed to validate the forwardFunds function for distributing tokens according to predefined splits.
    // However, it currently fails due to an assertion error where the expected balance does not match the actual balance.
    // The required total amount for distribution is 1,000 tokens, and the splits are [50, 40, 10] which should allocate
    // 500 tokens to recipient1, 400 tokens to recipient2, and 100 tokens to recipient3.
    // The logs show that recipient1 received 600 tokens, recipient2 received 500 tokens, and recipient3 received 200 tokens.
    // This discrepancy indicates that the forwardFunds function may not be calculating the distribution correctly or that
    // the transfer logic is flawed. Further investigation is needed to ensure that the amounts are calculated and transferred
    // correctly according to the split percentages.
    function testForwardFunds() public {
        uint256 totalAmount = 1000 * 10 ** 18;

        emit log_string("Required total amount for distribution:");
        emit log_uint(totalAmount);

        uint256[] memory splits = new uint256[](3);
        splits[0] = 50;
        splits[1] = 40;
        splits[2] = 10;

        address[] memory recipients = new address[](3);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;

        uint256 senderBalance = token.balanceOf(address(this));
        emit log_string("Sender balance before transfer:");
        emit log_uint(senderBalance);
        require(senderBalance >= totalAmount, "Insufficient balance");

        token.approve(address(zuvuFunds), totalAmount);

        uint256 allowance = token.allowance(owner, address(zuvuFunds));
        emit log_string("Allowance for ZuvuFunds:");
        emit log_uint(allowance);
        require(allowance >= totalAmount, "Insufficient allowance");

        zuvuFunds.forward_funds(totalAmount, splits, recipients);

        uint256 balance1 = token.balanceOf(recipient1);
        uint256 balance2 = token.balanceOf(recipient2);
        uint256 balance3 = token.balanceOf(recipient3);

        emit log_string("Balance of recipient1 after transfer:");
        emit log_uint(balance1);
        emit log_string("Balance of recipient2 after transfer:");
        emit log_uint(balance2);
        emit log_string("Balance of recipient3 after transfer:");
        emit log_uint(balance3);

        assertEq(balance1, (totalAmount * splits[0]) / 100);
        assertEq(balance2, (totalAmount * splits[1]) / 100);
        assertEq(balance3, (totalAmount * splits[2]) / 100);

        uint256 adjustedTotal = 0;
        uint256[] memory amounts = new uint256[](splits.length);

        amounts[0] = (totalAmount * splits[0]) / 100;
        amounts[1] = (totalAmount * splits[1]) / 100;
        amounts[2] = (totalAmount * splits[2]) / 100;

        emit log_string("Amounts to distribute:");
        emit log_uint(amounts[0]);
        emit log_uint(amounts[1]);
        emit log_uint(amounts[2]);

        for (uint256 i = 0; i < amounts.length; i++) {
            adjustedTotal += amounts[i];
        }

        uint256 adjustment = totalAmount - adjustedTotal;
        amounts[amounts.length - 1] += adjustment;

        emit log_string("Adjusted amounts after adjustment:");
        emit log_uint(amounts[0]);
        emit log_uint(amounts[1]);
        emit log_uint(amounts[2]);

        uint256 finalTotalDistributed = amounts[0] + amounts[1] + amounts[2];
        assertEq(finalTotalDistributed, totalAmount, "Adjusted total does not match total amount");
    }

    function testFailForwardFundsInvalidSplit() public {
        uint256[] memory splits = new uint256[](2);
        splits[0] = 60;
        splits[1] = 50; // Total > 100

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1;
        recipients[1] = recipient2;

        zuvuFunds.forward_funds(1000 * 10 ** 18, splits, recipients);
    }

    function testFailForwardFundsUnauthorized() public {
        vm.prank(recipient1);

        uint256[] memory splits = new uint256[](1);
        splits[0] = 100;

        address[] memory recipients = new address[](1);
        recipients[0] = recipient2;

        zuvuFunds.forward_funds(1000 * 10 ** 18, splits, recipients);
    }

    // ZuvuGovernance Tests

    function testProposalCreation() public {
        uint256[] memory splits = new uint256[](2);
        splits[0] = 60;
        splits[1] = 40;

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1;
        recipients[1] = recipient2;

        uint256 proposalId = zuvuGov.propose(splits, recipients);
        assertEq(proposalId, 1);

        (
            address proposer,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            uint256[] memory returnedSplits,
            address[] memory returnedRecipients,
            uint256 totalVotes
        ) = zuvuGov.getProposalDetails(proposalId);

        assertEq(proposer, address(this));
        assertEq(executed, false);
        assertEq(returnedSplits[0], splits[0]);
        assertEq(returnedSplits[1], splits[1]);
        assertEq(returnedRecipients[0], recipients[0]);
        assertEq(returnedRecipients[1], recipients[1]);
        assertEq(totalVotes, 0);
    }

    function testVotingAndExecution() public {
        // Create proposal
        uint256[] memory splits = new uint256[](2);
        splits[0] = 60;
        splits[1] = 40;

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1;
        recipients[1] = recipient2;

        uint256 proposalId = zuvuGov.propose(splits, recipients);

        // Cast votes
        vm.prank(recipient1);
        zuvuGov.castVote(proposalId);

        vm.prank(recipient2);
        zuvuGov.castVote(proposalId);

        // Wait for voting period to end
        vm.warp(block.timestamp + 4 days);

        // Execute proposal
        uint256 amount = 1000 * 10 ** 18;
        zuvuGov.executeProposal(proposalId, amount);

        // Verify transfers
        assertEq(token.balanceOf(recipient1), 100 * 10 ** 18 + (amount * 60) / 100);
        assertEq(token.balanceOf(recipient2), 100 * 10 ** 18 + (amount * 40) / 100);
    }

    function testDelegation() public {
        // Initial setup
        vm.prank(recipient2);
        zuvuGov.delegate(recipient1);

        // Create proposal
        uint256[] memory splits = new uint256[](2);
        splits[0] = 60;
        splits[1] = 40;

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1;
        recipients[1] = recipient2;

        uint256 proposalId = zuvuGov.propose(splits, recipients);

        // Vote with delegated power
        vm.prank(recipient1);
        zuvuGov.castVote(proposalId);

        // Check voting power includes delegation
        (,,,,,, uint256 totalVotes) = zuvuGov.getProposalDetails(proposalId);
        assertEq(totalVotes, 200 * 10 ** 18); // recipient1's balance + recipient2's delegated balance
    }

    receive() external payable {}
}
