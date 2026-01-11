// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Fluxion} from "../src/Fluxion.sol";

/// Simple Foundry script to call Fluxion.mint on the proxy as the admin.
/// Usage (example):
///   export RPC_URL="https://rpc.example"
///   export PRIVATE_KEY=0x...        # admin private key (same that received roles in initialize)
///   export PROXY_ADDRESS=0x...     # deployed ERC1967Proxy address (token)
///   export TO_ADDRESS=0x...        # recipient address (optional)
///   forge script script/InteractWithFluxion.s.sol:InteractWithFluxion --rpc-url $RPC_URL --broadcast
///
/// Notes:
/// - This script treats the proxy as the Fluxion interface: Fluxion token = Fluxion(proxy);
/// - Roles (MINTER_ROLE) must be granted to the admin during initialize (see [`src/Fluxion.sol`](src/Fluxion.sol:27)).
/// - You can pass PRIVATE_KEY to forge via env or via --private-key flag; vm.env* calls read env variables.
contract InteractWithFluxion is Script {
    function run() external {
        // Read environment variables (set them before running the script)
        uint256 adminKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(adminKey);
        address proxy = vm.envAddress("PROXY_ADDRESS");
        address to = vm.envAddress("TO_ADDRESS"); // set to admin if not provided (must set env or it'll be zero)

        // Amount to mint (adjust as needed)
        uint256 amount = 100 ether;

        // Start broadcasting transactions from admin
        vm.startBroadcast(adminKey);

        Fluxion token = Fluxion(proxy);

        address recipient = to == address(0) ? admin : to;
        token.mint(recipient, amount);

        vm.stopBroadcast();

        console.log("Mint called by admin:", admin);
        console.log("Recipient:", recipient);
        console.log("Amount (wei):", amount);
        console.log("Proxy (token):", proxy);
    }
}