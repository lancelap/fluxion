// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Fluxion} from "../src/Fluxion.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// Deploy script for Foundry (forge)
contract DeployFluxion is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1) Deploy implementation (logic contract)
        Fluxion impl = new Fluxion();

        // 2) Prepare initialize calldata (calls [`initialize(string,string,address)`](src/Fluxion.sol:27) on implementation via delegatecall)
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address)",
            "Fluxion",
            "FLX",
            deployer
        );

        // 3) Deploy ERC1967Proxy and initialize in the same tx
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        // 4) Interact with the proxy as the Fluxion token
        Fluxion token = Fluxion(address(proxy));

        vm.stopBroadcast();

        // Print addresses
        console.log("Deployer:", deployer);
        console.log("Implementation (logic):", address(impl));
        console.log("Proxy (token):", address(proxy));
        console.log("Token (proxy address):", address(token));
    }
}