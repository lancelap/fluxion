// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Factory} from "../src/Factory.sol";
import {Fluxion} from "../src/Fluxion.sol";

/// Simple smoke test script for the deployed Factory + implementation.
/// Usage:
/// 1) Set env vars:
///    - PRIVATE_KEY: deployer/admin private key (hex or decimal accepted by foundry env helpers)
///    - FACTORY_ADDRESS: address of deployed factory (optional; can be hardcoded below)
/// 2) Run:
///    forge script script/SmokeTestFactory.s.sol --rpc-url <RPC> --broadcast
contract SmokeTestFactory is Script {
    function run() external {
        // Read deployer key and factory address from environment
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address factoryAddr = vm.envAddress("FACTORY_ADDRESS"); // set this env var to 0x9d5D98... or your deployed address

        vm.startBroadcast(deployerKey);

        address admin = vm.addr(deployerKey);

        console.log("Using admin (address):", admin);
        console.log("Factory address:", factoryAddr);

        Factory factory = Factory(factoryAddr);

        // Prepare init calldata: initialize(string,string,address)
        bytes memory initData =
            abi.encodeWithSignature("initialize(string,string,address)", "FluxionFactory", "FLXF", admin);

        // Create a clone via factory
        address clone = factory.createClone(initData);
        console.log("Clone deployed at:", clone);

        // Verify clone state and perform a mint (admin is msg.sender because we broadcast with deployerKey)
        Fluxion token = Fluxion(clone);
        string memory name = token.name();
        string memory symbol = token.symbol();
        console.log("Clone name:", name);
        console.log("Clone symbol:", symbol);

        // Mint 1 ether to admin to verify MINTER_ROLE works
        token.mint(admin, 1 ether);
        uint256 bal = token.balanceOf(admin);
        console.log("Admin balance after mint (wei):", bal);

        vm.stopBroadcast();
    }
}
