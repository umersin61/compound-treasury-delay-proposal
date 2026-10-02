// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Escrow, Treasury} from "./TreasuryDelays.t.sol";

interface LifecycleVm {
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function envString(string calldata) external returns (string memory);
    function envOr(string calldata, uint256) external returns (uint256);
    function readFile(string calldata) external view returns (string memory);
    function parseJsonBytes(string calldata, string calldata) external pure returns (bytes memory);
    function prank(address) external;
    function roll(uint256) external;
    function warp(uint256) external;
    function expectRevert() external;
}

interface LiveGovernor {
    function clock() external view returns (uint48);
    function getVotes(address, uint256) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function quorum(uint256) external view returns (uint256);
    function latestProposalIds(address) external view returns (uint256);
    function state(uint256) external view returns (uint8);
    function proposalSnapshot(uint256) external view returns (uint256);
    function proposalDeadline(uint256) external view returns (uint256);
    function proposalEta(uint256) external view returns (uint256);
    function proposalVotes(uint256) external view returns (uint256, uint256, uint256);
    function castVote(uint256, uint8) external returns (uint256);
    function queue(uint256) external;
    function execute(uint256) external payable;
    function cancel(uint256) external;
    function isWhitelisted(address) external view returns (bool);
}

/// @notice Uses existing delegate checkpoints; never edits storage, balances, or the voting token.
/// @dev Impersonation represents hypothetical consent, not endorsement by any delegate.
contract GovernanceLifecycleForkTest {
    LifecycleVm constant vm = LifecycleVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    LiveGovernor constant governor = LiveGovernor(0x309a862bbC1A00e45506cB8A802D1ff10004c8C0);
    address constant TREASURY = 0xefeD08b791423C7D7937507Cf840E86a7ddC11c1;
    address constant ESCROW = 0xDcB34b56842F853A69E86De5A0c22c49d97C130C;
    address constant GOV_TIMELOCK = 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;
    address constant DELEGATE = address(bytes20(hex"3b6431fb5c71105cb3eab2cf058b135d4ccfc9c5"));
    address constant FOUNDATION = address(bytes20(hex"b06df4dd01a5c5782f360ada9345c87e86adae3d"));
    address constant WOOF = address(bytes20(hex"bfe2ff554d56527f679b746c777d73157724788d"));
    bytes32 constant OPERATION = 0x953db1c078de556930197fab4266b633d0b7fd28477d9028de81a438e6c6214d;
    address proposer;

    event DelegateCheckpoint(address delegate, uint256 votes, uint256 threshold, uint256 quorum);
    event GovernanceEnacted(uint256 proposalId, uint256 snapshot, uint256 deadline, uint256 eta);

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), vm.envOr("FORK_BLOCK", uint256(26101617)));
        require(governor.clock() == block.number, "Expected block-number governance clock");
        address[3] memory candidates = [DELEGATE, FOUNDATION, WOOF];
        for (uint256 i; i < candidates.length; ++i) {
            uint256 votes = governor.getVotes(candidates[i], governor.clock() - 1);
            emit DelegateCheckpoint(
                candidates[i], votes, governor.proposalThreshold(), governor.quorum(governor.clock() - 1)
            );
            uint256 latest = governor.latestProposalIds(candidates[i]);
            bool available = latest == 0 || governor.state(latest) > 1;
            if (
                proposer == address(0) && available
                    && (votes >= governor.proposalThreshold() || governor.isWhitelisted(candidates[i]))
            ) {
                proposer = candidates[i];
            }
        }
        require(proposer != address(0), "No existing eligible proposer available");
    }

    function _payload(string memory file) internal view returns (bytes memory) {
        return vm.parseJsonBytes(vm.readFile(file), ".data");
    }

    function _submit(string memory file) internal returns (uint256 id) {
        bytes memory data = _payload(file);
        require(
            bytes4(data) == bytes4(keccak256("propose(address[],uint256[],bytes[],string)")),
            "Wrong submission selector"
        );
        vm.prank(proposer);
        (bool ok, bytes memory result) = address(governor).call(data);
        if (!ok) {
            assembly { revert(add(result, 32), mload(result)) }
        }
        id = abi.decode(result, (uint256));
        require(governor.state(id) == 0, "Proposal not pending");
    }

    function _advance(uint256 targetBlock) internal {
        require(targetBlock > block.number, "Clock must advance");
        vm.warp(block.timestamp + (targetBlock - block.number) * 12);
        vm.roll(targetBlock);
    }

    function _passAndQueue(uint256 id) internal {
        vm.expectRevert();
        governor.queue(id);
        _advance(governor.proposalSnapshot(id) + 1);
        require(governor.state(id) == 1, "Proposal not active");
        vm.prank(DELEGATE);
        governor.castVote(id, 1);
        vm.prank(FOUNDATION);
        governor.castVote(id, 1);
        (, uint256 forVotes,) = governor.proposalVotes(id);
        require(forVotes >= governor.quorum(governor.proposalSnapshot(id)), "Existing delegates cannot reach quorum");
        _advance(governor.proposalDeadline(id) + 1);
        require(governor.state(id) == 4, "Proposal did not succeed");
        governor.queue(id);
        require(governor.state(id) == 5, "Proposal not queued");
        vm.expectRevert();
        governor.execute(id);
    }

    function _enact(string memory file) internal returns (uint256 id) {
        id = _submit(file);
        _passAndQueue(id);
        vm.warp(governor.proposalEta(id));
        governor.execute(id);
        require(governor.state(id) == 7, "Proposal not executed");
        emit GovernanceEnacted(
            id, governor.proposalSnapshot(id), governor.proposalDeadline(id), governor.proposalEta(id)
        );
    }

    function testBothPublishedSubmissionsThroughFullGovernance() public {
        require(Treasury(TREASURY).getTimestamp(OPERATION) == 0, "Operation already exists");
        _enact("proposal-1-submission.json");
        require(Escrow(ESCROW).expiration() == 1468800, "Expiration incorrect");
        require(Escrow(ESCROW).cooldown() == 864000, "Cooldown incorrect");
        require(Treasury(TREASURY).hasRole(keccak256("EXECUTOR_ROLE"), GOV_TIMELOCK), "Executor role missing");
        require(Treasury(TREASURY).hasRole(keccak256("CANCELLER_ROLE"), GOV_TIMELOCK), "Canceller role missing");
        require(Treasury(TREASURY).getMinDelay() == 172800, "Scheduling changed minimum delay");
        require(
            Treasury(TREASURY).getTimestamp(OPERATION) == block.timestamp + 172800, "Unexpected operation readiness"
        );
        _enact("proposal-2-submission.json");
        require(Treasury(TREASURY).getMinDelay() == 864000, "Final delay incorrect");
        require(Treasury(TREASURY).isOperationDone(OPERATION), "Operation not completed");
    }

    function testProposerCanCancelPendingPublishedProposal() public {
        uint256 id = _submit("proposal-1-submission.json");
        vm.prank(proposer);
        governor.cancel(id);
        require(governor.state(id) == 2, "Proposal not canceled");
        vm.expectRevert();
        governor.queue(id);
    }

    function testProposalWithoutVotesIsDefeated() public {
        uint256 id = _submit("proposal-1-submission.json");
        _advance(governor.proposalDeadline(id) + 1);
        require(governor.state(id) == 3, "Proposal without votes not defeated");
        vm.expectRevert();
        governor.queue(id);
    }

    function testIneligibleAccountCannotSubmitPublishedProposal() public {
        address account = address(0x8098);
        require(!governor.isWhitelisted(account), "Account unexpectedly whitelisted");
        require(
            governor.getVotes(account, governor.clock() - 1) < governor.proposalThreshold(),
            "Account unexpectedly eligible"
        );
        bytes memory data = _payload("proposal-1-submission.json");
        vm.prank(account);
        (bool ok,) = address(governor).call(data);
        require(!ok, "Ineligible proposal accepted");
    }
}
