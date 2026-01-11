// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Fluxion} from "../src/Fluxion.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/// Upgrade script for Foundry (UUPS) using a low-level call to the proxy's upgradeTo
/// This avoids compile-time lookup issues and prints the implementation address before/after.
/// Usage:
///   export RPC_URL="https://rpc..."
///   export PRIVATE_KEY=0x...        # must be account with UPGRADER_ROLE on the proxy
///   export PROXY_ADDRESS=0x...     # deployed ERC1967 proxy address
///   forge script script/UpgradeFluxion.s.sol:UpgradeFluxion --rpc-url $RPC_URL --broadcast
contract UpgradeFluxion is Script {
    function run() external {
        uint256 upgraderKey = vm.envUint("PRIVATE_KEY");
        address upgrader = vm.addr(upgraderKey);
        address proxy = vm.envAddress("PROXY_ADDRESS");

        // EIP1967 implementation slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
        bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

        // Read current implementation from the proxy storage using vm.load
        bytes32 implBeforeStorage = vm.load(proxy, implSlot);
        address implBefore = address(uint160(uint256(implBeforeStorage)));

        console.log("Current implementation (before):", implBefore);

        vm.startBroadcast(upgraderKey);

        // Upgrade the proxy using OpenZeppelin Foundry Upgrades helper.
        // `Upgrades.upgradeProxy` expects the contract name string (it will deploy the implementation for you),
        // so pass the artifact path "src/Fluxion.sol:Fluxion" and empty data.
        Upgrades.upgradeProxy(proxy, "src/Fluxion.sol:Fluxion", "");

        vm.stopBroadcast();

        // Read implementation after upgrade using Upgrades helper
        address implAfter = Upgrades.getImplementationAddress(proxy);

        console.log("Upgrader (caller):", upgrader);
        console.log("Proxy (token):", proxy);
        console.log("Implementation (after):", implAfter);
    }
}
