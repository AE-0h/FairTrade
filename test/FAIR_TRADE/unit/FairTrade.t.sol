// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console2} from "lib/forge-std/src/Test.sol";
import {IHooks} from "lib/v4-periphery/lib/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "lib/v4-periphery/lib/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "lib/v4-periphery/lib/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "lib/v4-periphery/lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {CurrencyLibrary, Currency} from "lib/v4-periphery/lib/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "lib/v4-periphery/lib/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "lib/v4-periphery/lib/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "lib/v4-periphery/lib/v4-core/test/foundry-tests/utils/Deployers.sol";
import {SimpleHookTest} from "../utils/SimpleHookTest.sol";
import {FairTrade} from "../../../src/FAIR_TRADE/FairTrade.sol";
import {HookMiner} from "../utils/HookMiner.sol";
import {FairTradeImplementation} from "../../../src/FAIR_TRADE/utils/FairTradeImplementation.sol";

contract FairTradeTest is SimpleHookTest, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    FairTrade public hook;
    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {
        SimpleHookTest.initHookTestEnv();

        // Deploy hook to an address with correct flags
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |
                Hooks.AFTER_INITIALIZE_FLAG |
                Hooks.BEFORE_MODIFY_POSITION_FLAG |
                Hooks.BEFORE_SWAP_FLAG // Not sure if we're gonna use this yet
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            0,
            type(FairTrade).creationCode,
            abi.encode(address(manager), "Test Token", "TEST", 18)
        );

        hook = new FairTrade{salt: salt}(
            IPoolManager(address(manager)),
            "Test Token",
            "TEST",
            18
        );

        require(
            address(hook) == hookAddress,
            "FairTradeTest: Hook address mismatch"
        );

        FairTradeImplementation impl = new FairTradeImplementation(
            manager,
            hook,
            "Test Token",
            "TEST",
            18
        );
        (, bytes32[] memory writes) = vm.accesses(address(impl));
        vm.etch(address(hook), address(impl).code);
        // for each storage key that was written during the hook implementation, copy the value over
        unchecked {
            for (uint256 i = 0; i < writes.length; i++) {
                bytes32 slot = writes[i];
                vm.store(address(hook), slot, vm.load(address(impl), slot));
            }
        }
    }

    function testDepositEth() public {
        hook.depositEth{value: 0.25 ether}();
        assertTrue(hook.isFunder(address(this)), "Not a funder");
    }

    function testFailDepositOnlyOnce() public {
        hook.depositEth{value: 0.25 ether}();
        hook.depositEth{value: 0.25 ether}();
    }

    function testFailDepositWrongAmount() public {
        hook.depositEth{value: 0.2 ether}();
    }

    function testFailDepositNoEth() public {
        hook.depositEth{value: 0.0 ether}();
    }

    function testQuit() public {
        hook.depositEth{value: 0.25 ether}();
        hook.quit();
        assertFalse(hook.isFunder(address(this)), "Still a funder");
    }

    function testFailQuitNotFunder() public {
        hook.quit();
    }

    function testLaunchToken() public {
        (address friend1, address friend2, address friend3, address friend4) = (
            address(0x1),
            address(0x2),
            address(0x3),
            address(0x4)
        );
        vm.deal(friend1, 10 ether);
        vm.deal(friend2, 10 ether);
        vm.deal(friend3, 10 ether);
        vm.deal(friend4, 10 ether);

        vm.prank(friend1);
        hook.depositEth{value: 0.25 ether}();
        vm.prank(friend2);
        hook.depositEth{value: 0.25 ether}();
        vm.prank(friend3);
        hook.depositEth{value: 0.25 ether}();
        vm.prank(friend4);
        hook.depositEth{value: 0.25 ether}();

        // hook.depositEth{value: 0.25 ether}();
        hook.launch();
    }

    receive() external payable {}
}
