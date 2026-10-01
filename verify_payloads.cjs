const fs = require('fs');
const assert = require('assert/strict');
let ethers;
try { ethers = require('ethers'); } catch { ethers = require('./tooling/node_modules/ethers'); }
const { Interface, AbiCoder, id, keccak256, toUtf8Bytes, getAddress } = ethers;
const m = JSON.parse(fs.readFileSync('transactions.json'));
const interfaces = {
 [m.addresses.escrow]: new Interface(JSON.parse(fs.readFileSync('escrow-abi.json'))),
 [m.addresses.treasuryTimelock]: new Interface(JSON.parse(fs.readFileSync('treasury-timelock-abi.json')))
};
for (const a of [...m.firstProposal,...m.secondProposal]) {
 assert.equal(interfaces[a.target].encodeFunctionData(a.signature,a.arguments),a.calldata);
 assert.equal(a.value,'0');
 const parsed=interfaces[a.target].parseTransaction({data:a.calldata});
 assert.equal(parsed.signature,a.signature);
}
assert.equal(m.salt,id(m.saltLabel));
for(const [role,hash] of Object.entries(m.roles)) assert.equal(hash,id(role+'_ROLE'));
const types=['address','uint256','bytes','bytes32','bytes32'];
const params=[m.addresses.treasuryTimelock,0,m.innerUpdateDelayCalldata,m.predecessor,m.salt];
assert.equal(keccak256(AbiCoder.defaultAbiCoder().encode(types,params)),m.operationId);
const treasury=interfaces[m.addresses.treasuryTimelock];
const scheduled=treasury.decodeFunctionData('schedule',m.firstProposal[4].calldata);
const executed=treasury.decodeFunctionData('execute',m.secondProposal[0].calldata);
for(let i=0;i<5;i++) assert.equal(scheduled[i].toString(),executed[i].toString());
assert.equal(scheduled[5],172800n);
assert.equal(treasury.decodeFunctionData('updateDelay',scheduled[2])[0],864000n);
const governor=new Interface(['function propose(address[],uint256[],bytes[],string) returns (uint256)']);
for (const name of ['proposal-1','proposal-2']) {
 const p=JSON.parse(fs.readFileSync(name+'.json'));
 const sub=JSON.parse(fs.readFileSync(name+'-submission.json'));
 assert.equal(governor.encodeFunctionData('propose',[p.targets,p.values,p.calldatas,p.description]),sub.data);
 assert.equal(keccak256(toUtf8Bytes(p.description)),sub.descriptionHash);
 assert.equal(getAddress(sub.to),getAddress('0x309a862bbc1a00e45506cb8a802d1ff10004c8c0'));
}
const live=JSON.parse(fs.readFileSync('live-preflight.json'));
assert(live['governor.hasAdmin'] && live['governor.hasPROPOSER']);
assert.equal(live['treasury.getMinDelay'],172800);
assert.equal(live['treasury.operationTimestamp'],0);
assert.equal(live['treasury.onchainOperationHash'],m.operationId);
assert.equal(live['escrow.TIMELOCK'].toLowerCase(),m.executionSender.toLowerCase());
assert(live['escrow.cooldown'] < 1468800 && 1468800 <= live['escrow.MAX_EXPIRATION']);
assert(864000 >= live['escrow.MIN_COOLDOWN'] && 864000 <= live['escrow.MAX_COOLDOWN']);
assert.notEqual(live['escrow.cooldown'],864000);
assert.notEqual(live['escrow.expiration'],1468800);
console.log('PASS: independent ethers encoding, six action decodes, both submission encodings, roles, salt, nested operation equality, on-chain hash, permissions, and parameter bounds.');
