# Compound treasury delay proposal

Unsigned Ethereum mainnet governance submissions for increasing the Treasury Escrow withdrawal cooldown and Treasury Timelock minimum delay to 10 days.

**7 fork tests passed, 0 failed, 0 skipped. All four CI jobs passed.** Both exact published submissions completed proposal creation, voting, quorum, queueing and execution through the existing Governor on a mainnet fork. The expanded first vote description includes the recent treasury movements reported in the forum and the custody instruction.

[Successful validation run](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904) · [Validated source](https://github.com/umersin61/compound-treasury-delay-proposal/commit/4a7a53247743fa1c636dda0b81d02549c250b4e4) · [Submission instructions](SUBMISSION.md)

## Actions

| № | Action name | Link | Status |
| --- | --- | --- | --- |
| 1 | Prepare / live preflight / ABI and import checks | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904/job/110681082214) | Success |
| 2 | Run Forge Tests / treasury scenarios and formatting | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904/job/110681082347) | Success |
| 3 | Run Tests With Gas Profiler | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904/job/110681082275) | Success |
| 4 | Run Enact by Delegator / both governance lifecycles | [Link](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904/job/110681082389) | Success |
| 5 | Tenderly proposal submissions | [Proposal 1](https://dashboard.tenderly.co/shared/simulation/365871be-ff0d-4a64-8b11-ac489f75d788) · [Proposal 2](https://dashboard.tenderly.co/shared/simulation/cce3e1b0-d7fd-4e5b-9817-00d6705a2dcc) | Success: submission only |

Two independent propose(...) submissions at mainnet block 26,101,617, using the exact published unsigned calldata and an impersonated existing eligible delegate. Both succeeded without storage, balance, vote or quorum overrides. Each returns simulated proposal ID 612. These links demonstrate submission only; the seven Foundry fork tests verify full two-stage governance and final treasury settings.

## Artifacts

| № | Name | Value |
| --- | --- | --- |
| 1 | Proposal package | `treasury-delays-8098` |
| 2 | Branch | `main` |
| 3 | Prepare id | `36956685904` |
| 4 | Network | `mainnet` |
| 5 | Contracts | Treasury Escrow / Treasury Timelock |
| 6 | Validated source commit | `4a7a53247743fa1c636dda0b81d02549c250b4e4` |
| 7 | Prepared payloads | [Download](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904/artifacts/11205768590) |
| 8 | Full governance enactment | [Download](https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904/artifacts/11206376411) |
| 9 | Cactus imports | [First](proposal-1-cactus-actions.json) · [Follow-up](proposal-2-cactus-actions.json) |

The immutable source commit above contains the tested submissions and import files. Later evidence and documentation commits preserve their executable bytes. Trace logs are also committed for review without artifact downloads.

## Environment

| Parameter | Value |
| --- | --- |
| Chain | Ethereum mainnet (1) |
| Pinned block | 26,101,617 |
| Timestamp | 2026-10-02 02:21:23 UTC |
| Block hash | `0x9c49a1271d9f1aca7145795adc96a2db65acb6843b4b62321a19845cd9b65217` |
| Forge / Solidity | 1.7.1 / 0.8.34 |
| Proposer threshold | 25,000 delegated COMP at the prior block |
| Voting delay / period | 13,140 / 19,710 blocks |
| Governor Timelock | 172,800 seconds |

## Proposed actions

The first proposal executes five calls in this order, all with zero ETH:

1. Set Escrow expiration to 1,468,800 seconds (17 days from initiation).
2. Set Escrow withdrawal cooldown to 864,000 seconds (10 days).
3. Grant Governor Timelock `EXECUTOR_ROLE` on Treasury Timelock.
4. Grant Governor Timelock `CANCELLER_ROLE` on Treasury Timelock.
5. Schedule Treasury Timelock self-call `updateDelay(864000)` using the existing 172,800-second minimum delay.

Expiration must increase before cooldown. Scheduling does not change the minimum delay. The follow-up executes the identical operation once ready; an existing authorized executor can also complete it.

The custody clause is a governance instruction, with no separately enforceable call. Existing withdrawals and scheduled operations retain their timing. These controls do not retroactively recover funds or enforce custody outside their contracts.

## Contracts

| Contract | Mainnet address |
| --- | --- |
| Governor | `0x309a862bbC1A00e45506cB8A802D1ff10004c8C0` |
| Governor Timelock | `0x6d903f6003cca6255D85CcA4D3B5E5146dC33925` |
| Treasury Escrow | `0xDcB34b56842F853A69E86De5A0c22c49d97C130C` |
| Treasury Timelock | `0xefeD08b791423C7D7937507Cf840E86a7ddC11c1` |

## Validation scope

The action tests cover ordered two-stage execution, cancellation and rejection of increasing cooldown before expiration. The lifecycle tests cover both complete published submissions, ineligible proposer rejection, defeat without votes and pending proposal cancellation.

Tests use real mainnet contract bytecode, storage and existing delegate checkpoints. They impersonate the Governor or delegates and use hypothetical votes. They do not modify storage, balances, delegation or quorum. The proposer used was `0x3B6431fb5C71105cB3EaB2Cf058B135d4cCFc9C5`; the additional simulated voter was `0xb06DF4dD01a5c5782f360aDA9345C87E86ADAe3D`. This does not imply endorsement. Fork IDs 612 and 613 are simulation identifiers. No live proposal or transaction was broadcast.

The submitting wallet remains unspecified and its eligibility is not established. Guardian intervention, real voting participation and concurrent treasury changes are outside the simulation. This configuration proposal deploys no Solidity implementation or Comet market; market migration suites and static analyzers were not run. Gas figures are test measurements, not fee quotes.

## Reproduce

```sh
MAINNET_RPC_URL=https://ethereum-rpc.publicnode.com FORK_BLOCK=26101617 forge test -vvvv
npm ci --ignore-scripts
npm run verify
python -m pip install -r requirements.txt
python scripts/check_rebuild.py
python build_payloads.py
MAINNET_RPC_URL=https://ethereum-rpc.publicnode.com PREFLIGHT_BLOCK=latest node scripts/refresh_preflight.cjs
sha256sum --check SHA256SUMS
```

Fork reproduction requires an archive endpoint that serves the recorded block; the public endpoint now requires a personal token for older state. Supply an appropriate `MAINNET_RPC_URL` for the fork. Regeneration does not refresh recorded fork results. CI keeps the fork pinned and checks live treasury preconditions at the latest block minus two using `PREFLIGHT_BLOCK=latest`; the chosen preflight block and hash appear in the job output. The committed preflight records remain the verified simulation-block snapshot. The preflight fails if treasury preconditions have changed.

## Files

`transactions.json` contains all six decoded actions and complete calldata. `proposal-1.json` and `proposal-2.json` contain Governor arguments; `*-submission.json` are complete unsigned calls to `propose(address[],uint256[],bytes[],string)`. `*-description.txt` contains the exact encoded UTF-8 description with no terminal newline. `*-cactus-title.txt` and `*-cactus-body.txt` split that text for the builder; `*-cactus-actions.json` imports only the proposal actions, not the outer Governor submission.

`validation.json` records checks and scope. `live-preflight.json` and `governor-preflight.json` record pinned state. `simulation.log`, `governance-enactment.log` and `gas-profile.log` contain real run output. `SHA256SUMS` covers the package files. Source and ABIs permit independent encoding and reproduction.

## Operation identity

```text
Salt: 0x703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa
Operation ID: 0x953db1c078de556930197fab4266b633d0b7fd28477d9028de81a438e6c6214d
```

Scheduling and execution must use the same target, value, nested calldata, predecessor and salt. Before live submission or execution, refresh state and confirm that the operation is unused or ready, as appropriate.
