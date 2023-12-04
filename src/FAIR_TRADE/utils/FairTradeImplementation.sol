/*

 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/undefined?utm=code
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {FairTrade} from "../FairTrade.sol";

import {BaseHook} from "lib/v4-periphery/contracts/BaseHook.sol";
import {IPoolManager} from "lib/v4-periphery/lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "lib/v4-periphery/lib/v4-core/contracts/libraries/Hooks.sol";

contract FairTradeImplementation is FairTrade {
    constructor(
        IPoolManager poolManager,
        FairTrade addressToEtch,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) FairTrade(poolManager, name, symbol, decimals) {
        Hooks.validateHookAddress(addressToEtch, getHooksCalls());
    }

    function validateHookAddress(BaseHook _this) internal pure override {}
}
