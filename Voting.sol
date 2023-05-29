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

// Errors
error AlreadyRegisterVoter(address invalidVoter);
error UnRegisteredVoter(address invalidVoter);
error WrongPhaseStatus(WorkflowStatus requiredStatus, WorkflowStatus status);
error AlreadyVoted(address invalidVote);
error WrongProposal(uint256 invalidProposal);
error MissingVoteOfVoter(address invalidVoter);
error VotersNotYetRegistered();

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

    // Test
    // mapping(uint => mapping(address => Voter) sessions;

    Session session;

    constructor() {
        session.status = WorkflowStatus.RegisteringVoters;
    }

    function _resetProposals() internal onlyOwner {
        delete session.proposals;
        for (uint256 i = 0; i < session.idxVoters.length; i++) {
            session.voters[session.idxVoters[i]].hasVoted = false;
            session.voters[session.idxVoters[i]].votedProposalId = 0;
        }
    }

    function _resetVoters() internal onlyOwner {
        delete session.proposals;
        for (uint256 i = 0; i < session.idxVoters.length; i++) {
            session.voters[session.idxVoters[i]] = Voter(false, false, 0);
        }
    }

    function _resetVotes() internal onlyOwner {
        for (uint256 i = 0; i < session.idxVoters.length; i++) {
            session.voters[session.idxVoters[i]].hasVoted = false;
            session.voters[session.idxVoters[i]].votedProposalId = 0;
        }
        for (uint256 j = 0; j < session.proposals.length; j++) {
            session.proposals[j].voteCount = 0;
        }
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

    modifier votesTallied() {
        _wrongPhase(WorkflowStatus.VotesTallied);
        _;
    }

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
        session.voters[_voter] = Voter(true, false, 0);
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
    function startProposalRegistration()
        external
        onlyOwner
        registerVoterActive
    {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.ProposalsRegistrationStarted;

        // we must exclude 0 from the vote;
        session.proposals[0] = Proposal("void bulletin", 0);

        emit WorkflowStatusChange(status, session.status);
    }

    function endProposalRegistration()
        external
        onlyOwner
        registerProposalActive
    {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(status, session.status);
    }

    function registerProposal(string memory description)
        external
        onlyVoters
        registerProposalActive
    {
        // Todo: unique proposals
        uint256 proposalId = session.proposals.length;
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

    function vote(uint256 proposalId) external onlyVoters {
        if (proposalId >= session.proposals.length && proposalId == 0) {
            revert WrongProposal(proposalId);
        }
        if (session.voters[msg.sender].hasVoted) {
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

    function tallyVotes() external voteSessionDone {
        uint256 maxVoteCount = 0;
        uint256 mainProposal = 0;
        for (uint256 i = 1; i < session.proposals.length; i++) {
            if (session.proposals[i].voteCount > maxVoteCount) {
                maxVoteCount = session.proposals[i].voteCount;
                mainProposal = i;
            }
        }

        session.winningProposalId = mainProposal;

        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(status, session.status);
    }

    function getWinner()
        external
        view
        onlyVoters
        votesTallied
        returns (uint256)
    {
        return session.winningProposalId;
    }

    /*
    
    VOTE DETAILS 
    
    */
    function getAllVoters()
        external
        view
        onlyVoters
        returns (address[] memory)
    {
        return session.idxVoters;
    }

    function getAllProposals()
        external
        view
        onlyVoters
        returns (Proposal[] memory)
    {
        require(
            session.status != WorkflowStatus.RegisteringVoters,
            unicode"Please wait voters' registration to be closed"
        );

        return session.proposals;
    }

    function getVoteOfVoter(address _voter) external view onlyVoters returns (uint256) {
        if(session.status == WorkflowStatus.RegisteringVoters) {
            revert VotersNotYetRegistered();
        }

        if (!session.voters[_voter].isRegistered) {
            revert UnRegisteredVoter(_voter);
        }

        if(session.voters[_voter].votedProposalId == 0) {
            revert MissingVoteOfVoter(_voter);
        }
        
        return session.voters[_voter].votedProposalId;
    }

    /*
    RESET
    */

    function resetSession() external onlyOwner {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.RegisteringVoters;

        _resetVoters();

        emit WorkflowStatusChange(status, session.status);
    }

    function resetProposals() external onlyOwner {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.VotingSessionStarted;

        _resetProposals();

        emit WorkflowStatusChange(status, session.status);
    }

    function resetVotes() external onlyOwner {
        WorkflowStatus status = session.status;
        session.status = WorkflowStatus.VotingSessionStarted;

        _resetVotes();

        emit WorkflowStatusChange(status, session.status);
    }
}
