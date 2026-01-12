// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import {Fluxion} from "../src/Fluxion.sol";
import {Factory} from "../src/Factory.sol";

/// @notice Deploys Fluxion implementation and Factory that points to it.
/// Usage (foundry):
///   forge script script/DeployFactory.s.sol --private-key <KEY> --broadcast
contract DeployFactory is Script {
    function run() external {
        // Expects PRIVATE_KEY env var or pass --private-key on CLI
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        Fluxion impl = new Fluxion();
        Factory factory = new Factory(address(impl));

        console.log("Deployer key (hex):", deployerKey);
        console.log("Fluxion implementation deployed at:", address(impl));
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
