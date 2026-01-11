// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Fluxion} from "../src/Fluxion.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/// Deploy script for Foundry (forge)
contract DeployFluxion is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Prepare initialize calldata (include trustedForwarder param)
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address,address)",
            "Fluxion",
            "FLX",
            deployer
        );

        // Deploy UUPS proxy and implementation using OpenZeppelin Foundry Upgrades helper.
        // The helper will deploy the implementation and create an ERC1967 proxy pointing to it,
        // calling `initialize` (delegatecall) on creation with `initData`.
        address proxyAddr = Upgrades.deployUUPSProxy("src/Fluxion.sol:Fluxion", initData);

        // Interact with the proxy as the Fluxion token
        Fluxion token = Fluxion(proxyAddr);

        vm.stopBroadcast();

        // Print addresses
        console.log("Deployer:", deployer);
        console.log("Implementation (logic):", Upgrades.getImplementationAddress(proxyAddr));
        console.log("Proxy (token):", proxyAddr);
        console.log("Token (proxy address):", address(token));
    }
}