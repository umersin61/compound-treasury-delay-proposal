"""Read pinned mainnet state; print reproducible evidence without broadcasting."""
import datetime
import json
import os
import urllib.request
from pathlib import Path
from eth_abi import encode, decode
from eth_utils import keccak

ROOT = Path(__file__).resolve().parents[1]
RPC = os.environ.get('MAINNET_RPC_URL', 'https://rpc.flashbots.net')
BLOCK = int(os.environ['FORK_BLOCK'])

def rpc(method, params):
    request = urllib.request.Request(RPC, data=json.dumps(dict(jsonrpc='2.0', id=1, method=method, params=params)).encode(), headers={'Content-Type': 'application/json', 'User-Agent': 'compound-treasury-delay-proposal/1.0'})
    result = json.load(urllib.request.urlopen(request, timeout=60))
    if 'error' in result:
        raise RuntimeError(result['error'])
    return result['result']

checks = json.loads((ROOT / 'preflight-calls.json').read_text())
for name, output in [('timelock', 'address'), ('votingDelay', 'uint256'), ('votingPeriod', 'uint256'), ('proposalThreshold', 'uint256')]:
    checks.append(dict(label='governor.' + name, target='0x309a862bbc1a00e45506cb8a802d1ff10004c8c0', callData='0x' + keccak(text=name + '()')[:4].hex(), outputType=output))
values = {}
for check in checks:
    result = rpc('eth_call', [dict(to=check['target'], data=check['callData']), hex(BLOCK)])
    value = decode([check['outputType']], bytes.fromhex(result[2:]))[0]
    values[check['label']] = '0x' + value.hex() if isinstance(value, bytes) else value
block = rpc('eth_getBlockByNumber', [hex(BLOCK), False])
assert values['blockNumber'] == BLOCK
expected = json.loads((ROOT / 'live-preflight.json').read_text())
for name, value in expected.items():
    if name not in ('blockNumber', 'blockTimestamp'):
        assert values[name] == value, (name, values[name], value)
assert values['governor.proposalThreshold'] == 25000000000000000000000
assert values['governor.timelock'].lower() == '0x6d903f6003cca6255d85cca4d3b5e5146dc33925'
evidence = dict(blockNumber=BLOCK, blockHash=block['hash'], blockTimeUTC=datetime.datetime.fromtimestamp(int(block['timestamp'],16), datetime.timezone.utc).isoformat(), values=values)
print('PREFLIGHT_JSON=' + json.dumps(evidence, separators=(',', ':')))
print('PASS: all pinned treasury settings, roles, operation identity, unused operation, Governor timelock and proposal threshold.')
