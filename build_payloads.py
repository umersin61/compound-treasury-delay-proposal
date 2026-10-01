import json, os, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'pydeps'))
from eth_abi import encode, decode
from eth_utils import keccak, to_checksum_address

ROOT = Path(__file__).parent
ESCROW = to_checksum_address('0xDcB34b56842F853A69E86De5A0c22c49d97C130C')
TREASURY = to_checksum_address('0xefeD08b791423C7D7937507Cf840E86a7ddC11c1')
GOVERNOR_TIMELOCK = to_checksum_address('0x6d903f6003cca6255D85CcA4D3B5E5146dC33925')
MULTICALL = to_checksum_address('0xcA11bde05977b3631167028862bE2a173976CA11')
GOVERNOR = to_checksum_address('0x309a862bbc1a00e45506cb8a802d1ff10004c8c0')
ZERO = '0x' + '00' * 32
SALT_LABEL = 'compound:mainnet:8098:treasury-delay-10-days:2026-10-02:v1'
SALT = '0x' + keccak(text=SALT_LABEL).hex()
ROLES = {name: '0x' + keccak(text=name + '_ROLE').hex() for name in ('PROPOSER','EXECUTOR','CANCELLER')}

def calldata(signature, types=(), args=()):
    return '0x' + (keccak(text=signature)[:4] + encode(types, args)).hex()

def action(target, signature, types, args, effect):
    data = calldata(signature, types, args)
    decoded = decode(types, bytes.fromhex(data[10:]))
    assert encode(types, decoded) == encode(types, args)
    return dict(target=target, value='0', signature=signature, arguments=[('0x'+x.hex()) if isinstance(x,bytes) else x for x in args], calldata=data, argumentCalldata='0x'+data[10:], effect=effect)

def build():
    inner = calldata('updateDelay(uint256)', ['uint256'], [864000])
    op_types = ['address','uint256','bytes','bytes32','bytes32']
    op_args = [TREASURY,0,bytes.fromhex(inner[2:]),bytes(32),bytes.fromhex(SALT[2:])]
    operation_id = '0x' + keccak(encode(op_types,op_args)).hex()
    first = [
      action(ESCROW,'setWithdrawExpiration(uint40)',['uint40'],[1468800],'17-day expiration from initiation'),
      action(ESCROW,'setWithdrawCooldown(uint40)',['uint40'],[864000],'10-day cooldown'),
      action(TREASURY,'grantRole(bytes32,address)',['bytes32','address'],[bytes.fromhex(ROLES['EXECUTOR'][2:]),GOVERNOR_TIMELOCK],'Grant Governor Timelock EXECUTOR'),
      action(TREASURY,'grantRole(bytes32,address)',['bytes32','address'],[bytes.fromhex(ROLES['CANCELLER'][2:]),GOVERNOR_TIMELOCK],'Grant Governor Timelock CANCELLER'),
      action(TREASURY,'schedule(address,uint256,bytes,bytes32,bytes32,uint256)',op_types+['uint256'],op_args+[172800],'Schedule self-call to updateDelay(864000), after existing two-day delay')
    ]
    second = [action(TREASURY,'execute(address,uint256,bytes,bytes32,bytes32)',op_types,op_args,'Execute scheduled self-call; minimum delay becomes 10 days')]
    manifest = dict(chainId=1,source='https://www.comp.xyz/t/aligning-treasury-delays-with-the-governance-process/8098/6',executionSender=GOVERNOR_TIMELOCK,addresses=dict(escrow=ESCROW,treasuryTimelock=TREASURY,governorTimelock=GOVERNOR_TIMELOCK),saltLabel=SALT_LABEL,salt=SALT,predecessor=ZERO,operationId=operation_id,innerUpdateDelayCalldata=inner,roles=ROLES,firstProposal=first,secondProposal=second,validationStatus='ABI round-trip verified; live-state preflight and fork simulation status in validation.json')
    (ROOT/'transactions.json').write_text(json.dumps(manifest,indent=2)+'\n')
    descriptions = [
      '# Aligning Treasury Delays with the Governance Process\n\nSet the Treasury Escrow expiration to 17 days from initiation, then its withdrawal cooldown to 10 days. Grant the Governor Timelock EXECUTOR_ROLE and CANCELLER_ROLE on the Treasury Timelock. Schedule a Treasury Timelock self-call to updateDelay(864000), using its existing 172800-second minimum delay. A separate execution is required once that operation becomes ready.\n\nTreasury assets administered by the TMC shall be held in the Treasury Escrow or in contracts owned by the Treasury Timelock. The TMC Safe may hold treasury assets only in transit, for no longer than needed to complete a disbursement that has passed through the Escrow cooldown or the Treasury Timelock delay. This clause is a governance instruction and is not enforced by the executable calls.\n\nForum: https://www.comp.xyz/t/aligning-treasury-delays-with-the-governance-process/8098\n\nOperation ID: '+operation_id,
      '# Complete the Treasury Timelock Delay Increase\n\nExecute the Treasury Timelock self-call scheduled by the first proposal for Aligning Treasury Delays with the Governance Process. This sets its minimum delay for newly scheduled operations to 864000 seconds (10 days). Execution must occur after the scheduled operation is ready and while it remains uncancelled.\n\nOperation ID: '+operation_id
    ]
    for index, (name, actions) in enumerate([('proposal-1',first),('proposal-2',second)]):
      args = dict(targets=[a['target'] for a in actions],values=[a['value'] for a in actions],calldatas=[a['calldata'] for a in actions],description=descriptions[index])
      (ROOT/(name+'.json')).write_text(json.dumps(args,indent=2)+'\n')
      (ROOT/(name+'-description.txt')).write_text(descriptions[index]+'\n')
      submission = dict(chainId=1,to=GOVERNOR,value='0',data=calldata('propose(address[],uint256[],bytes[],string)',['address[]','uint256[]','bytes[]','string'],[args['targets'],[0]*len(actions),[bytes.fromhex(d[2:]) for d in args['calldatas']],args['description']]),function='propose(address[],uint256[],bytes[],string)',descriptionHash='0x'+keccak(text=args['description']).hex(),status='Prepared only; refer to validation.json for simulation status; proposer eligibility not verified')
      (ROOT/(name+'-submission.json')).write_text(json.dumps(submission,indent=2)+'\n')
    checks=[]
    def add(label,target,sig,types=(),args=(),out='uint256'):
      checks.append(dict(label=label,target=target,allowFailure=True,callData=calldata(sig,types,args),outputType=out))
    add('blockNumber',MULTICALL,'getBlockNumber()')
    add('blockTimestamp',MULTICALL,'getCurrentBlockTimestamp()')
    for n,t in [('cooldown','uint40'),('expiration','uint40'),('MIN_COOLDOWN','uint40'),('MAX_COOLDOWN','uint40'),('MAX_EXPIRATION','uint40'),('TIMELOCK','address')]: add('escrow.'+n,ESCROW,n+'()',out=t)
    add('treasury.getMinDelay',TREASURY,'getMinDelay()')
    for role in ['PROPOSER','EXECUTOR','CANCELLER']:
      add('treasury.'+role+'_ROLE',TREASURY,role+'_ROLE()',out='bytes32')
      add('governor.has'+role,TREASURY,'hasRole(bytes32,address)',['bytes32','address'],[bytes.fromhex(ROLES[role][2:]),GOVERNOR_TIMELOCK],out='bool')
    add('governor.hasAdmin',TREASURY,'hasRole(bytes32,address)',['bytes32','address'],[bytes(32),GOVERNOR_TIMELOCK],out='bool')
    for role in ['EXECUTOR','CANCELLER']:
      add('treasury.'+role+'Admin',TREASURY,'getRoleAdmin(bytes32)',['bytes32'],[bytes.fromhex(ROLES[role][2:])],out='bytes32')
    add('treasury.operationTimestamp',TREASURY,'getTimestamp(bytes32)',['bytes32'],[bytes.fromhex(operation_id[2:])])
    add('treasury.onchainOperationHash',TREASURY,'hashOperation(address,uint256,bytes,bytes32,bytes32)',op_types,op_args,out='bytes32')
    add('governorTimelock.admin',GOVERNOR_TIMELOCK,'admin()',out='address')
    add('governorTimelock.delay',GOVERNOR_TIMELOCK,'delay()')
    (ROOT/'preflight-calls.json').write_text(json.dumps(checks,indent=2)+'\n')
    print(json.dumps(dict(salt=SALT,operationId=operation_id,innerCalldata=inner,selectors=[a['calldata'][:10] for a in first],checkCount=len(checks)),indent=2))

if __name__=='__main__': build()
