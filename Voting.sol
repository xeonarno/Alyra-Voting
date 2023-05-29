// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// Enum
enum WorkflowStatus {
    RegisteringVoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded,
    VotesTallied
}

error AlreadyRegisterVoter(address invalidVoter);
error UnRegisteredVoter(address invalidVoter);
error WrongPhaseStatus(WorkflowStatus requiredStatus, WorkflowStatus status);
error AlreadyVoted(address invalidVote);
error WrongProposal(uint invalidProposal);

contract Voting is Ownable {
    // Events
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    // Objects
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    struct Session {
        WorkflowStatus status;
        mapping(address => Voter) voters;
        address[] idxVoters;
        Proposal[] proposals;
        uint256 winningProposalId; // Le gagnant
    }

    Session session;

    constructor() {
        _resetVoting();
    }

    function _resetVoting() private onlyOwner {
        session.status = WorkflowStatus.RegisteringVoters;
        resetProposal();
   
    }

    /*

        MODIFIERS 

    */

    modifier onlyVoters() {
        if (!session.voters[msg.sender].isRegistered) {
            revert UnRegisteredVoter(msg.sender);
        }
        _;
    }

    function _wrongPhase(WorkflowStatus _status) internal view {
        if (session.status != _status) {
            revert WrongPhaseStatus(_status, session.status);
        }
    }

    modifier registerVoterActive() {
        _wrongPhase(WorkflowStatus.RegisteringVoters);
        _;
    }
    modifier registerProposalActive() {
         _wrongPhase(WorkflowStatus.ProposalsRegistrationStarted);
        _;
    }

    modifier registerProposalDone() {
         _wrongPhase(WorkflowStatus.ProposalsRegistrationEnded);
        _;
    }

    modifier voteSessionActive() {
         _wrongPhase(WorkflowStatus.VotingSessionStarted);
        _;
    }

    modifier voteSessionDone() {
         _wrongPhase(WorkflowStatus.VotingSessionStarted);
        _;
    }
 //TODO VotesTallied
    /*

        VOTERS

    */

    function registerVoter(address _voter)
        public
        onlyOwner
        registerVoterActive
    {
        if (!session.voters[_voter].isRegistered) {
            revert AlreadyRegisterVoter(_voter);
        }

        session.idxVoters.push(_voter);
        session.voters[_voter].isRegistered = true;
        emit VoterRegistered(_voter);
    }

    function registerVoters(address[] memory _voters)
        external
        onlyOwner
        registerVoterActive
    {
        for (uint256 i = 0; i <= _voters.length; i++) {
            registerVoter(_voters[i]);
        }
    }

    /*

    REGISTRATION

    */
    function startProposalRegistration() external onlyOwner registerVoterActive {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(status, session.status);
    }

    function endProposalRegistration() external onlyOwner registerProposalActive {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(status, session.status);
    }

    function registerProposal(string memory description) external onlyVoters registerProposalActive { 
        // Todo: unique proposals
        uint proposalId = session.proposals.length;
        session.proposals.push(Proposal(description, 0));
        emit ProposalRegistered(proposalId);
    }

    /*

    VOTE

    */
  function startVoteSession() external onlyOwner registerProposalDone {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(status, session.status);
    }

    function endVoteSession() external onlyOwner voteSessionActive {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(status, session.status);
    }

    function vote(uint proposalId) external onlyVoters {
        if(proposalId >= session.proposals.length) {
            revert WrongProposal(proposalId);
        }
        if(session.voters[msg.sender].hasVoted) {
            revert AlreadyVoted(msg.sender);
        }
        session.voters[msg.sender].hasVoted = true;
        session.voters[msg.sender].votedProposalId = proposalId;
        session.proposals[proposalId].voteCount++;
        emit Voted(msg.sender, proposalId);
    }

    /*

    RESULTS;

    */

    function tallyVotes () external voteSessionDone {
         WorkflowStatus status = session.status;
        session.status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(status, session.status);
    }

    function getWinner() external view returns (address) {
        return address(this); // TBD
    }

    function getVoteDetails() external view returns (Proposal[] memory) {
        return session.proposals;
    }

    /*
    RESET
    */

    function resetVoters() external onlyOwner {
             if (session.idxVoters.length > 0) {
            for (uint256 i = 0; i < session.idxVoters.length; i++) {
                session.voters[session.idxVoters[i]].isRegistered = false;
            }
        }
    }
    function resetSession() external onlyOwner {
        _resetVoting();
    }

    function resetVote() external onlyOwner {

    }

    function resetProposal() public onlyOwner {
        delete session.proposals;
    }

}
