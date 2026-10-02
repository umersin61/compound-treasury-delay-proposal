// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface Vm {
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function envString(string calldata) external returns (string memory);
    function envOr(string calldata, uint256) external returns (uint256);
    function prank(address) external;
    function warp(uint256) external;
}

interface GovTimelock {
    function delay() external view returns (uint256);
    function queueTransaction(address, uint256, string calldata, bytes calldata, uint256) external returns (bytes32);
    function executeTransaction(address, uint256, string calldata, bytes calldata, uint256)
        external
        payable
        returns (bytes memory);
}

interface Treasury {
    function getMinDelay() external view returns (uint256);
    function getTimestamp(bytes32) external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function isOperationDone(bytes32) external view returns (bool);
    function cancel(bytes32) external;
}

interface Escrow {
    function cooldown() external view returns (uint40);
    function expiration() external view returns (uint40);
    function setWithdrawCooldown(uint40) external;
}

contract TreasuryDelaysForkTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address constant GOVERNOR = 0x309a862bbC1A00e45506cB8A802D1ff10004c8C0;
    address constant GOV_TIMELOCK = 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;
    address constant TREASURY = 0xefeD08b791423C7D7937507Cf840E86a7ddC11c1;
    address constant ESCROW = 0xDcB34b56842F853A69E86De5A0c22c49d97C130C;
    bytes32 constant OPERATION = 0x953db1c078de556930197fab4266b633d0b7fd28477d9028de81a438e6c6214d;
    uint256 eta;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), vm.envOr("FORK_BLOCK", uint256(26101617)));
    }

    function _executeThroughGovernorTimelock(address target, bytes memory data) internal {
        vm.prank(GOVERNOR);
        GovTimelock(GOV_TIMELOCK).executeTransaction(target, 0, "", data, eta);
    }

    function _queue(address target, bytes memory data) internal {
        vm.prank(GOVERNOR);
        GovTimelock(GOV_TIMELOCK).queueTransaction(target, 0, "", data, eta);
    }

    function _stageOne() internal {
        require(Treasury(TREASURY).getMinDelay() == 172800, "Current delay changed");
        require(Treasury(TREASURY).getTimestamp(OPERATION) == 0, "Operation ID used");
        eta = block.timestamp + GovTimelock(GOV_TIMELOCK).delay();
        _queue(
            0xDcB34b56842F853A69E86De5A0c22c49d97C130C,
            hex"adbab6c30000000000000000000000000000000000000000000000000000000000166980"
        );
        _queue(
            0xDcB34b56842F853A69E86De5A0c22c49d97C130C,
            hex"87acd00900000000000000000000000000000000000000000000000000000000000d2f00"
        );
        _queue(
            0xefeD08b791423C7D7937507Cf840E86a7ddC11c1,
            hex"2f2ff15dd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e630000000000000000000000006d903f6003cca6255d85cca4d3b5e5146dc33925"
        );
        _queue(
            0xefeD08b791423C7D7937507Cf840E86a7ddC11c1,
            hex"2f2ff15dfd643c72710c63c0180259aba6b2d05451e3591a24e58b62239378085726f7830000000000000000000000006d903f6003cca6255d85cca4d3b5e5146dc33925"
        );
        _queue(
            0xefeD08b791423C7D7937507Cf840E86a7ddC11c1,
            hex"01d5062a000000000000000000000000efed08b791423c7d7937507cf840e86a7ddc11c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa000000000000000000000000000000000000000000000000000000000002a300000000000000000000000000000000000000000000000000000000000000002464d6235300000000000000000000000000000000000000000000000000000000000d2f0000000000000000000000000000000000000000000000000000000000"
        );
        vm.warp(eta);
        _executeThroughGovernorTimelock(
            0xDcB34b56842F853A69E86De5A0c22c49d97C130C,
            hex"adbab6c30000000000000000000000000000000000000000000000000000000000166980"
        );
        _executeThroughGovernorTimelock(
            0xDcB34b56842F853A69E86De5A0c22c49d97C130C,
            hex"87acd00900000000000000000000000000000000000000000000000000000000000d2f00"
        );
        _executeThroughGovernorTimelock(
            0xefeD08b791423C7D7937507Cf840E86a7ddC11c1,
            hex"2f2ff15dd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e630000000000000000000000006d903f6003cca6255d85cca4d3b5e5146dc33925"
        );
        _executeThroughGovernorTimelock(
            0xefeD08b791423C7D7937507Cf840E86a7ddC11c1,
            hex"2f2ff15dfd643c72710c63c0180259aba6b2d05451e3591a24e58b62239378085726f7830000000000000000000000006d903f6003cca6255d85cca4d3b5e5146dc33925"
        );
        _executeThroughGovernorTimelock(
            0xefeD08b791423C7D7937507Cf840E86a7ddC11c1,
            hex"01d5062a000000000000000000000000efed08b791423c7d7937507cf840e86a7ddc11c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa000000000000000000000000000000000000000000000000000000000002a300000000000000000000000000000000000000000000000000000000000000002464d6235300000000000000000000000000000000000000000000000000000000000d2f0000000000000000000000000000000000000000000000000000000000"
        );
        require(Escrow(ESCROW).expiration() == 1468800, "Expiration");
        require(Escrow(ESCROW).cooldown() == 864000, "Cooldown");
        require(Treasury(TREASURY).hasRole(keccak256("EXECUTOR_ROLE"), GOV_TIMELOCK), "Executor");
        require(Treasury(TREASURY).hasRole(keccak256("CANCELLER_ROLE"), GOV_TIMELOCK), "Canceller");
        require(Treasury(TREASURY).getMinDelay() == 172800, "Schedule must not change delay");
        require(Treasury(TREASURY).getTimestamp(OPERATION) == block.timestamp + 172800, "Ready time");
    }

    function testTwoStageExecution() public {
        _stageOne();
        bytes memory data =
            hex"134008d3000000000000000000000000efed08b791423c7d7937507cf840e86a7ddc11c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa000000000000000000000000000000000000000000000000000000000000002464d6235300000000000000000000000000000000000000000000000000000000000d2f0000000000000000000000000000000000000000000000000000000000";
        vm.prank(GOV_TIMELOCK);
        (bool early,) = TREASURY.call(data);
        require(!early, "Early execution succeeded");
        eta = block.timestamp + GovTimelock(GOV_TIMELOCK).delay();
        require(eta >= Treasury(TREASURY).getTimestamp(OPERATION), "Governor delay too short");
        _queue(TREASURY, data);
        vm.warp(eta);
        _executeThroughGovernorTimelock(TREASURY, data);
        require(Treasury(TREASURY).getMinDelay() == 864000, "Ten-day delay not set");
        require(Treasury(TREASURY).isOperationDone(OPERATION), "Operation not done");
    }

    function testGovernanceCanCancelScheduledDelayChange() public {
        _stageOne();
        vm.prank(GOV_TIMELOCK);
        Treasury(TREASURY).cancel(OPERATION);
        require(Treasury(TREASURY).getTimestamp(OPERATION) == 0, "Cancellation failed");
        vm.warp(block.timestamp + 172800);
        vm.prank(GOV_TIMELOCK);
        (bool ok,) = TREASURY.call(
            hex"134008d3000000000000000000000000efed08b791423c7d7937507cf840e86a7ddc11c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000703a0be5ed4c07d8ca94f71da77bd59768fc6588d87567765ac518e895705aaa000000000000000000000000000000000000000000000000000000000000002464d6235300000000000000000000000000000000000000000000000000000000000d2f0000000000000000000000000000000000000000000000000000000000"
        );
        require(!ok, "Cancelled operation executed");
    }

    function testCooldownFirstRevertsAtPinnedConfiguration() public {
        require(Escrow(ESCROW).expiration() == 604800, "Pinned expiration changed");
        vm.prank(GOV_TIMELOCK);
        (bool ok,) = ESCROW.call(abi.encodeCall(Escrow.setWithdrawCooldown, (uint40(864000))));
        require(!ok, "Invalid action order succeeded");
    }
}
