// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {Upgrades, UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Fluxion as FluxionV1} from "../src/Fluxion.sol";
import {Fluxion as FluxionV2} from "../src/FluxionV2.sol";

contract UpgradeFluxionV1ToV2Test is Test {
    function test_upgrade_preserves_state() public {
        // keys
        uint256 adminPk = 0xAB;
        address admin = vm.addr(adminPk);

        uint256 ownerPk = 0x1;
        address owner = vm.addr(ownerPk);

        // 1) Deploy V1 via Upgrades helper (it will deploy implementation + proxy and call initialize)
        bytes memory initV1 = abi.encodeWithSignature("initialize(string,string,address)", "Fluxion", "FLX", admin);

        address proxy = Upgrades.deployUUPSProxy("Fluxion.sol:Fluxion", initV1);
        FluxionV1 tokenV1 = FluxionV1(proxy);

        // 2) Use V1: mint tokens to owner (admin is minter)
        vm.prank(admin);
        tokenV1.mint(owner, 1_000 ether);
        assertEq(tokenV1.balanceOf(owner), 1_000 ether);

        // Check role in V1
        bytes32 minterRole = tokenV1.MINTER_ROLE();
        assertTrue(tokenV1.hasRole(minterRole, admin));

        // 3) Deploy V2 implementation contract (logic) directly
        FluxionV2 newImpl = new FluxionV2();

        // 4) Upgrade proxy to new implementation using UnsafeUpgrades (no validations in test env)
        // Use `admin` as the caller so the upgrade passes AccessControl checks (admin has UPGRADER_ROLE)
        UnsafeUpgrades.upgradeProxy(proxy, address(newImpl), "", admin);

        // 5) Cast proxy to V2 and verify state preserved and new features available
        FluxionV2 tokenV2 = FluxionV2(proxy);

        // Balances preserved
        assertEq(tokenV2.balanceOf(owner), 1_000 ether);

        // Roles preserved
        assertTrue(tokenV2.hasRole(minterRole, admin));

        // New field _trustedForwarder exists in V2; default is address(0)
        assertTrue(tokenV2.isTrustedForwarder(address(0)));
    }
}
