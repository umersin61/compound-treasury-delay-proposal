# Compound treasury delay proposal

Transaction payloads and a reproducible Ethereum mainnet fork simulation for increasing the Treasury Escrow withdrawal cooldown and Treasury Timelock minimum delay to 10 days.

**Fork result: 7 passed, 0 failed, 0 skipped.** Both published submissions passed through proposal creation, voting, quorum, queueing and execution on the existing Governor.

[Proposal review PR](https://github.com/umersin61/compound-treasury-delay-proposal/pull/1) · [Successful validation run](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875)

## Actions

| № | Action name | Link | Status |
| --- | --- | --- | --- |
| 1 | Prepare Migration | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/job/110304071227) | Success |
| 2 | Run Forge Tests / treasury scenarios | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/job/110304071454) | Success |
| 3 | Run Tests With Gas Profiler | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/job/110304071522) | Success |
| 4 | Run Enact by Delegator | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/job/110304071628) | Success |
| 5 | ABI encoding / deterministic payload unit checks | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/job/110304071227) | Success |
| 6 | Contract formatting | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/job/110304071454) | Success |
| 7 | Tenderly Simulation (mainnet) | — | Not run: no publishing access available |

This is a treasury configuration proposal. No Comet deployment, market migration, or new Solidity implementation is included. Comet market scenarios, its unit suite, Slither, Semgrep, ESLint and Solhint from the Comet proposal pipeline were not run. The successful checks above apply to this repository and do not imply completion of those other checks. Gas values are fork test measurements, not transaction fee quotes.

## Artifacts

| № | Name | Value |
| --- | --- | --- |
| 1 | Proposal package | `treasury-delays-8098` |
| 2 | Branch name | `treasury-delays/full-governance-validation` |
| 3 | Prepare id | `36842316875` |
| 4 | Network | `mainnet` |
| 5 | Contracts | Treasury Escrow / Treasury Timelock |
| 6 | Validated source commit | `412805feca6c35ad20ac2a030868bea3e9a526ac` |
| 7 | Prepared payload artifact | [Download](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/artifacts/11152420261) |
| 8 | Governor enactment artifact | [Download](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36842316875/artifacts/11150899328) |

The recorded run validates the immutable source commit above. Later documentation commits preserve that source and payloads. Full enactment traces are also committed as `governance-enactment.log` so reviewers can read them without downloading a CI artifact.

| Environment | Value |
| --- | --- |
| Chain | Ethereum mainnet (chain ID 1) |
| Pinned block | 26,094,833 |
| Block timestamp | 2026-10-01 03:39:23 UTC |
| Block hash | `0xdf709374144ccf5a15919d1543b4a09825a29c9dc4008e9b8c7da1a5da23e68d` |
| Foundry | Forge 1.7.1 |
| Solidity | 0.8.34 |

## Proposed actions

The first proposal executes five actions in this order:

1. Set Treasury Escrow withdrawal expiration to 1,468,800 seconds (17 days from initiation).
2. Set Treasury Escrow withdrawal cooldown to 864,000 seconds (10 days).
3. Grant the Governor Timelock `EXECUTOR_ROLE` on the Treasury Timelock.
4. Grant the Governor Timelock `CANCELLER_ROLE` on the Treasury Timelock.
5. Schedule a Treasury Timelock self-call to `updateDelay(864000)` using its existing 172,800-second delay.

The second payload executes the identical scheduled operation after it becomes ready. Scheduling alone does not change the minimum delay. An existing authorized executor can complete the operation without a second proposal.

## Contracts

| Contract | Ethereum mainnet address |
| --- | --- |
| Governor | [0x309a862bbC1A00e45506cB8A802D1ff10004c8C0](https://etherscan.io/address/0x309a862bbC1A00e45506cB8A802D1ff10004c8C0) |
| Governor Timelock | [0x6d903f6003cca6255D85CcA4D3B5E5146dC33925](https://etherscan.io/address/0x6d903f6003cca6255D85CcA4D3B5E5146dC33925) |
| Treasury Escrow | [0xDcB34b56842F853A69E86De5A0c22c49d97C130C](https://etherscan.io/address/0xDcB34b56842F853A69E86De5A0c22c49d97C130C) |
| Treasury Timelock | [0xefeD08b791423C7D7937507Cf840E86a7ddC11c1](https://etherscan.io/address/0xefeD08b791423C7D7937507Cf840E86a7ddC11c1) |

## Simulation scope

The Foundry tests use real mainnet contract bytecode and storage. The action tests impersonate the current Governor to queue and execute the exact actions through the existing Governor Timelock. The additional lifecycle tests read the exact `data` bytes in both published unsigned submission files and call the existing Governor, using existing eligible delegate checkpoints and simulated votes. They never edit contract storage, token balances, delegation or quorum.

| Test | Result | Checks |
| --- | --- | --- |
| `testTwoStageExecution` | PASS | Ordered actions, resulting settings, both roles, operation readiness, early execution rejection, final 10-day delay |
| `testGovernanceCanCancelScheduledDelayChange` | PASS | Cancellation succeeds and prevents later execution |
| `testCooldownFirstRevertsAtPinnedConfiguration` | PASS | Increasing the cooldown before expiration reverts |
| `testBothPublishedSubmissionsThroughFullGovernance` | PASS | Both complete submissions, eligible proposer, real vote checkpoints, quorum, voting clocks, queueing, Governor timelock, early queue/execution rejection, final settings |
| `testIneligibleAccountCannotSubmitPublishedProposal` | PASS | Governor rejects the published submission from an ineligible account |
| `testProposalWithoutVotesIsDefeated` | PASS | A proposal without votes is defeated and cannot be queued |
| `testProposerCanCancelPendingPublishedProposal` | PASS | Proposer cancels through the Governor; canceled proposal cannot be queued |

The successful lifecycle test impersonates `0x3B6431fb5C71105cB3EaB2Cf058B135d4cCFc9C5` as proposer and voter, and `0xb06DF4dD01a5c5782f360aDA9345C87E86ADAe3D` as another voter. This is hypothetical consent, not delegate endorsement. Proposal IDs 612 and 613 exist only in the fork; no live proposal or transaction was submitted. The eventual submitting wallet's eligibility is not established by these tests. Guardian intervention, live participation, concurrent treasury actions and successful adoption are not guaranteed. Existing requests and operations retain their timing. The custody instruction in the first vote description has no separate enforceable call.

## Reproduce

With Foundry installed, run from the repository root:

```sh
MAINNET_RPC_URL=https://rpc.flashbots.net FORK_BLOCK=26094833 forge test -vvvv
```

`MAINNET_RPC_URL` can be any Ethereum mainnet archive endpoint that serves the pinned block. The test defaults to block 26,094,833 when `FORK_BLOCK` is unset.

Independent ABI encoding checks:

```sh
npm ci
npm run verify
```

Regenerate proposal payloads:

```sh
python -m pip install -r requirements.txt
python build_payloads.py
```

Check regeneration without overwriting recorded evidence:

```sh
python scripts/check_rebuild.py
```

The builder also writes preflight request inputs for fresh state checks. Regeneration does not rerun or refresh the recorded fork evidence.

## Files

| File | Purpose |
| --- | --- |
| `test/TreasuryDelays.t.sol` | Executed fork test source |
| `test/GovernanceLifecycle.t.sol` | Complete proposal and voting lifecycle test source |
| `.github/workflows/proposal-validation.yml` | Reproducible public checks and artifact uploads |
| `foundry.toml` | Compiler configuration |
| `simulation.log` | Full `-vvvv` execution trace |
| `governance-enactment.log` | Full published-submission enactment trace from GitHub Actions |
| `gas-profile.log` | Gas-profiler test results for all seven tests |
| `simulation-summary.txt` | Test result excerpt |
| `validation.json` | Pinned environment, results and scope |
| `live-preflight.json`, `governor-preflight.json` | Recorded pinned-state checks |
| `transactions.json` | Six decoded actions, full calldata, salt and operation ID |
| `proposal-1.json`, `proposal-2.json` | Current Governor proposal arguments |
| `proposal-1-submission.json`, `proposal-2-submission.json` | Complete unsigned proposal submissions |
| `proposal-1-description.txt`, `proposal-2-description.txt` | Vote descriptions encoded in the submissions |
| `build_payloads.py`, `verify_payloads.cjs` | Payload generation and independent verification |
| `escrow-abi.json`, `treasury-timelock-abi.json` | Verified contract ABIs |
| `SHA256SUMS` | Checksums for the evidence package |

The Governor accepts `propose(address[],uint256[],bytes[],string)` with complete function calldata. All actions attach zero ETH. An eligible proposer and successful governance process are required to enact the changes. Editing a vote description requires re-encoding its submission. Refresh on-chain state before submission and execution.

## Operation identity

```text
Salt: 0x703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa
Operation ID: 0x953db1c078de556930197fab4266b633d0b7fd28477d9028de81a438e6c6214d
```

The target, ETH value, nested calldata, predecessor and salt must match between scheduling and execution. Do not execute an operation already completed or cancelled.
