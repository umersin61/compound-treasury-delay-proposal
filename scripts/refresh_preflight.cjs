// Read pinned public mainnet state through the ethers JSON-RPC client.
const fs = require('fs');
const assert = require('assert/strict');
const { JsonRpcProvider, AbiCoder, id } = require('ethers');
const requested = process.env.PREFLIGHT_BLOCK || process.env.FORK_BLOCK;
let block = Number(requested);
if (requested !== 'latest') assert(Number.isSafeInteger(block) && block > 0, 'Set FORK_BLOCK or PREFLIGHT_BLOCK=latest');
const provider = new JsonRpcProvider(process.env.MAINNET_RPC_URL || 'https://ethereum-rpc.publicnode.com', 1, {staticNetwork: true, batchMaxCount: 1});
const abi = AbiCoder.defaultAbiCoder();
async function main() {
 if (requested === 'latest') block = Number(BigInt(await provider.send('eth_blockNumber',[]))) - 2;
 const tag = '0x' + block.toString(16);
 const checks = JSON.parse(fs.readFileSync('preflight-calls.json', 'utf8'));
 for (const [name, outputType] of [['timelock','address'],['votingDelay','uint256'],['votingPeriod','uint256'],['proposalThreshold','uint256']]) checks.push({label:'governor.'+name,target:'0x309a862bbc1a00e45506cb8a802d1ff10004c8c0',callData:id(name+'()').slice(0,10),outputType});
 const values = {};
 for (const check of checks) {
  const raw = await provider.send('eth_call', [{to: check.target, data: check.callData}, tag]);
  const value = abi.decode([check.outputType],raw)[0];
  values[check.label] = typeof value === 'bigint' ? (check.label === 'governor.proposalThreshold' ? value.toString() : Number(value)) : (typeof value === 'string' ? value.toLowerCase() : value);
 }
 const expected = JSON.parse(fs.readFileSync('live-preflight.json','utf8'));
 assert.equal(values.blockNumber, block);
 for (const [name,value] of Object.entries(expected)) if (!['blockNumber','blockTimestamp'].includes(name)) assert.equal(values[name],typeof value === 'string' ? value.toLowerCase() : value, name);
 assert.equal(values['governor.proposalThreshold'],'25000000000000000000000');
 assert.equal(values['governor.timelock'],'0x6d903f6003cca6255d85cca4d3b5e5146dc33925');
 const header = await provider.send('eth_getBlockByNumber',[tag,false]);
 console.log('PREFLIGHT_JSON='+JSON.stringify({blockNumber:block,blockHash:header.hash,blockTimeUTC:new Date(Number(BigInt(header.timestamp))*1000).toISOString(),values}));
 console.log('PASS: all pinned treasury settings, roles, operation identity, unused operation, Governor timelock and proposal threshold.');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;}).finally(()=>provider.destroy());
