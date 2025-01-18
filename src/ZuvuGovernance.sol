// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ZuvuGovernance is ReentrancyGuard, AccessControl {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        uint256[] splits;
        address[] recipients;
        uint256 totalVotes;
        mapping(address => uint256) votes;
    }

    struct Vote {
        bool hasVoted;
        uint256 weight;
    }

    IERC20 public token;
    uint256 public proposalCount;
    uint256 public votingPeriod;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public delegates;
    mapping(address => mapping(uint256 => Vote)) public votes;
    mapping(address => uint256) public delegatedPower;

    event ProposalCreated(uint256 indexed proposalId, address proposer, uint256 startTime, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    constructor(address _token) {
        token = IERC20(_token);
        votingPeriod = 3 days;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROPOSER_ROLE, msg.sender);
        _setupRole(EXECUTOR_ROLE, msg.sender);
    }

    function propose(uint256[] memory _splits, address[] memory _recipients) 
        external 
        onlyRole(PROPOSER_ROLE) 
        returns (uint256)
    {
        require(_splits.length == _recipients.length, "Invalid proposal parameters");
        require(_splits.length > 0, "Empty proposal");
        
        uint256 totalSplit = 0;
        for (uint256 i = 0; i < _splits.length; i++) {
            totalSplit += _splits[i];
        }
        require(totalSplit == 100, "Invalid split total");

        uint256 proposalId = ++proposalCount;
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.splits = _splits;
        proposal.recipients = _recipients;

        emit ProposalCreated(proposalId, msg.sender, proposal.startTime, proposal.endTime);
        return proposalId;
    }

    function delegate(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to self");
        address currentDelegate = delegates[msg.sender];
        
        // Remove power from current delegate
        if (currentDelegate != address(0)) {
            delegatedPower[currentDelegate] -= token.balanceOf(msg.sender);
        }
        
        // Add power to new delegate
        if (delegatee != address(0)) {
            delegatedPower[delegatee] += token.balanceOf(msg.sender);
        }
        
        delegates[msg.sender] = delegatee;
        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
    }

    function getVotingPower(address account) public view returns (uint256) {
        return token.balanceOf(account) + delegatedPower[account];
    }

    function castVote(uint256 proposalId) external nonReentrant {
        require(block.timestamp <= proposals[proposalId].endTime, "Voting period ended");
        require(!votes[msg.sender][proposalId].hasVoted, "Already voted");

        uint256 weight = getVotingPower(msg.sender);
        require(weight > 0, "No voting power");

        votes[msg.sender][proposalId] = Vote(true, weight);
        proposals[proposalId].votes[msg.sender] = weight;
        proposals[proposalId].totalVotes += weight;

        emit VoteCast(proposalId, msg.sender, weight);
    }

    function executeProposal(uint256 proposalId, uint256 amount) 
        external 
        nonReentrant 
        onlyRole(EXECUTOR_ROLE) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Already executed");
        require(proposal.totalVotes > 0, "No votes cast");

        proposal.executed = true;

        // Execute transfers based on splits
        for (uint256 i = 0; i < proposal.splits.length; i++) {
            uint256 transferAmount = (amount * proposal.splits[i]) / 100;
            require(
                token.transferFrom(msg.sender, proposal.recipients[i], transferAmount),
                "Transfer failed"
            );
        }

        emit ProposalExecuted(proposalId);
    }

    function getProposalDetails(uint256 proposalId) 
        external 
        view 
        returns (
            address proposer,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            uint256[] memory splits,
            address[] memory recipients,
            uint256 totalVotes
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.splits,
            proposal.recipients,
            proposal.totalVotes
        );
    }
}
