// Compare exported wallet transaction data to the published unsigned submission.
const fs = require('fs');
const assert = require('assert/strict');
const [proposal, file] = process.argv.slice(2);
assert(['proposal-1', 'proposal-2'].includes(proposal) && file, 'Usage: node scripts/check_wallet_transaction.cjs proposal-1 wallet-transaction.json');
const expected = JSON.parse(fs.readFileSync(proposal + '-submission.json', 'utf8'));
const text = fs.readFileSync(file, 'utf8').trim();
const actual = text.startsWith('{') ? JSON.parse(text) : {data: text};
assert.equal(actual.data?.toLowerCase(), expected.data.toLowerCase(), 'Governor calldata differs: actions or description changed');
if (actual.to !== undefined) assert.equal(actual.to.toLowerCase(), expected.to.toLowerCase(), 'Wrong transaction recipient');
if (actual.value !== undefined) assert.equal(BigInt(actual.value), 0n, 'ETH value must be zero');
if (actual.chainId !== undefined) assert.equal(BigInt(actual.chainId), 1n, 'Wrong chain');
console.log('PASS: calldata matches the published and simulated submission byte for byte.');
if (actual.to === undefined || actual.value === undefined || actual.chainId === undefined) console.log('Recipient, zero ETH value and Ethereum mainnet must also be checked in the wallet.');
