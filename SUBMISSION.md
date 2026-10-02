# Submit the treasury delay proposal

Submit **proposal 1 only** now. Proposal 2 is a follow-up execution of the scheduled Treasury Timelock operation.

The first description has been rebuilt to include the recent treasury movements reported in the forum. It and the exact submission passed full governance fork validation at mainnet block 26,101,617. The evidence and imports are already published on `main`; no further PR or merge is required to submit the proposal. A GitHub merge does not create an on-chain proposal.

## 1. Publish the evidence update in the forum

Copy the supplied `forum-post.txt` into the existing discussion. Use Discourse's Markdown/source editor (`M`), then check the preview. Keep the prepared title and on-chain description unchanged when moving to Cactus. The forum post is supplied separately from the public code package.

## 2. Open Compound on Cactus

Open https://www.tally.xyz/gov/compound/proposals and choose **+ New proposal**. Cactus is the renamed Tally platform.

Connect the wallet that will submit the proposal on Ethereum mainnet. At the verified block, the Governor requires at least **25,000 delegated COMP votes at the preceding block**. A token balance alone is not voting power. The wallet must also have ETH for gas. If the connected wallet does not meet the threshold, an eligible delegate must submit the prepared proposal; creating a draft does not bypass this rule. Simulations impersonate an eligible delegate and do not establish your wallet's eligibility.

Cactus currently redirects proposal creation to **Sign in to create a proposal / Connect wallet**. You complete this wallet connection and the final transaction in your own browser; no forum login is involved.

## 3. Enter the exact title and description

- Title: copy `proposal-1-cactus-title.txt` — `Aligning Treasury Delays with the Governance Process`.
- Description: copy `proposal-1-cactus-body.txt` as Markdown. It starts with `Summary` followed by `-------`; this matches the final Markdown produced by the Cactus editor. Do not repeat the title in the body or add a leading blank line.

The complete description encoded in the tested submission is `# ` + title + one newline character + body, with no extra terminal newline. It is also available in `proposal-1-description.txt` and the `description` field of `proposal-1.json`.

Do not append a different forum reply URL, change wording, add a simulation link, or alter spacing after validation. The reference links already appear in the tested text. An altered description requires rebuilding and revalidating the submission. Check the rendered preview for literal Markdown or a duplicated title.

## 4. Import the five actions

In the proposal builder choose **Import Actions**, upload **`proposal-1-cactus-actions.json`**, then click **Import**. The documented format is Safe Transaction Builder JSON. The package includes complete calldata and ABI method metadata, independently checked against the verified contract ABIs.

**Import the actions file, not `proposal-1-submission.json`.** Do not send the imported batch directly from a Safe. These calls must execute through Compound governance and its Governor Timelock.

Confirm exactly these five actions, in this order, each sending **0 ETH**:

| Order | Target | Method | Arguments |
| --- | --- | --- | --- |
| 1 | Treasury Escrow | `setWithdrawExpiration(uint40)` | `1468800` |
| 2 | Treasury Escrow | `setWithdrawCooldown(uint40)` | `864000` |
| 3 | Treasury Timelock | `grantRole(bytes32,address)` | EXECUTOR role below; Governor Timelock below |
| 4 | Treasury Timelock | `grantRole(bytes32,address)` | CANCELLER role below; Governor Timelock below |
| 5 | Treasury Timelock | `schedule(address,uint256,bytes,bytes32,bytes32,uint256)` | Treasury Timelock; `0`; inner calldata below; zero predecessor; salt below; `172800` |

```text
Treasury Escrow: 0xDcB34b56842F853A69E86De5A0c22c49d97C130C
Treasury Timelock: 0xefeD08b791423C7D7937507Cf840E86a7ddC11c1
Governor Timelock: 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925
EXECUTOR_ROLE: 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63
CANCELLER_ROLE: 0xfd643c72710c63c0180259aba6b2d05451e3591a24e58b62239378085726f783
Inner calldata (updateDelay(864000)): 0x64d6235300000000000000000000000000000000000000000000000000000000000d2f00
Predecessor: 0x0000000000000000000000000000000000000000000000000000000000000000
Salt: 0x703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa
```

If import is unavailable, use **Custom Action**, select each target and method, then enter the arguments above. Upload `escrow-abi.json` or `treasury-timelock-abi.json` if the builder cannot load the ABI. Keep the order; increasing cooldown before expiration reverts at the tested configuration.

## 5. Preview, simulate and check the wallet transaction

Preview the proposal. Cactus documents automatic executable-action simulation; inspect its result under **Executable code**. Require successful results for all five calls before publishing. A live state change can invalidate a previously successful simulation.

The final wallet transaction must be:

```text
Network: Ethereum mainnet, chain ID 1
Recipient: 0x309a862bbC1A00e45506cB8A802D1ff10004c8C0 (current Governor)
ETH value: 0
Function: propose(address[],uint256[],bytes[],string)
Action count: 5
Expected description hash: 0x82f0b7d85c7bcfec335056b094348e83a0ee7f3859ed8ca7748c5fe91d6efeee
```

The exact expected transaction calldata is the `data` field of `proposal-1-submission.json`. The proposer supplied decoded wallet parameters; the first submission was rebuilt to match their title, description, ordered targets, zero values and all five complete action calldatas. Raw outer calldata, chain ID and outer ETH value were not supplied. Verify those wallet fields as well. If the wallet can copy/export transaction data, save it as JSON (or save only the raw hex data) and compare from the repository root:

```sh
node scripts/check_wallet_transaction.cjs proposal-1 wallet-transaction.json
```

This checks every calldata byte, including title/body formatting. It also checks recipient, value and chain when those fields are included. If it reports a difference, do not sign that transaction; the changed bytes need review and revalidation.

Choose **Publish** when the preview and transaction match, and sign the proposal-creation transaction in your wallet. This creates the proposal; it does not immediately execute the treasury changes. After confirmation, copy the real Cactus proposal link and transaction hash to the forum. IDs 612 and 613 in fork logs are simulations; use the actual ID assigned on-chain.

## 6. Complete governance for proposal 1

At the verified configuration, voting starts after 13,140 blocks and runs for 19,710 blocks. Follow the actual Cactus status and deadline rather than a calendar estimate. Seek delegate votes; hypothetical simulation votes are not endorsements.

If the proposal succeeds, **Queue** it. After the Governor Timelock's two-day delay, **Execute** it. Queue and execute are separate on-chain transactions with gas costs. Check the actual state and readiness before each transaction.

After execution, confirm:

- Escrow cooldown: `864000`.
- Escrow expiration: `1468800`.
- Governor Timelock holds Treasury Timelock EXECUTOR and CANCELLER roles.
- The operation below has been scheduled; its timestamp is greater than `1`.

```text
Operation ID: 0x953db1c078de556930197fab4266b633d0b7fd28477d9028de81a438e6c6214d
```

The Treasury Timelock minimum delay remains two days at this point. The custody clause is a governance instruction; these calls do not enforce Safe custody or recover assets. Existing withdrawal requests and scheduled operations retain their original timing.

## 7. Complete the scheduled delay increase

The Treasury operation becomes ready two days after **proposal 1 executes and schedules it**, not two days after proposal submission. Check `getTimestamp(operationId)` and `isOperationReady(operationId)` on the Treasury Timelock. Confirm the operation has not been cancelled or completed.

Once ready, use the same Cactus process for the prepared follow-up:

- Title: `proposal-2-cactus-title.txt`.
- Description: `proposal-2-cactus-body.txt`.
- Action import: `proposal-2-cactus-actions.json` (exactly **one** `execute(...)` action).
- Expected unsigned submission: `proposal-2-submission.json`.

Proposal 2 must pass its own voting, queueing and Governor execution process. An existing authorized Treasury executor may instead execute the same ready operation directly; if that happens, the follow-up is unnecessary. Do not submit or execute an already completed operation.

Finally confirm Treasury Timelock `getMinDelay()` equals **`864000`** and the operation is done. Only then are both delay changes complete.

## Evidence

- CI: https://github.com/umersin61/compound-treasury-delay-proposal/actions/runs/36956685904
- First submission: https://dashboard.tenderly.co/shared/simulation/365871be-ff0d-4a64-8b11-ac489f75d788
- Follow-up submission: https://dashboard.tenderly.co/shared/simulation/cce3e1b0-d7fd-4e5b-9817-00d6705a2dcc

Tenderly verifies two independent submissions only. Foundry verifies both complete governance lifecycles and the final contract state. No live transaction was broadcast during preparation.

## Cactus references

- Proposal creation: https://docs.tally.xyz/how-to-use-tally/proposals/creating-proposals/
- Action imports: https://docs.tally.xyz/how-to-use-tally/proposals/creating-proposals/import-and-export-proposal-actions/
- Description standard: https://docs.tally.xyz/set-up-and-technical-documentation/governor-proposals/whats-the-standard-for-governor-proposal-descriptions/

The public entry point and current wallet connection requirement were observed directly. Import steps follow the official documentation. The final description and decoded calls were supplied by the proposer from their wallet; the agent did not connect or sign in that wallet.
