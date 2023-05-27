// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

enum WorkflowStatus {
    RegisteringVoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded,
    VotesTallied
}

contract Voting is Ownable {
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    struct Request {
        WorkflowStatus status;
        Voter[] voter;
        Proposal[] proposals;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    uint256 winningProposalId; // Le gagnant

    Request ballot;

    constructor() {
        ballot.status = WorkflowStatus.RegisteringVoters;
    }
    /*

    REGISTRATION

    */

    /*

    VOTE

    */


    /*

    RESULTS;

    */

    function getWinner() external view returns (address) {
        return address(this); // TBD
    }

    function getVoteDetails() external view returns (Proposal[] memory) {
        return ballot.proposals;
    }
}
