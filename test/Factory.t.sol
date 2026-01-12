// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {Fluxion} from "../src/Fluxion.sol";
import {Factory} from "../src/Factory.sol";

contract FactoryTest is Test {
    Fluxion impl;
    Factory factory;

    address admin;
    uint256 adminPk;

    address owner;
    uint256 ownerPk;

    function setUp() public {
        adminPk = 0xAB;
        admin = vm.addr(adminPk);

        ownerPk = 0x1;
        owner = vm.addr(ownerPk);

        // Deploy implementation and factory
        impl = new Fluxion();
        factory = new Factory(address(impl));
    }

    function test_createClone_initializes_and_allows_minting() public {
        // Prepare initializer calldata for Fluxion.initialize(string,string,address)
        bytes memory initData = abi.encodeWithSignature("initialize(string,string,address)", "Fluxion", "FLX", admin);

        // Create clone and assert initialization occurred
        address cloneAddr = factory.createClone(initData);
        Fluxion clone = Fluxion(cloneAddr);

        assertEq(clone.name(), "Fluxion");
        assertEq(clone.symbol(), "FLX");

        // Admin should have MINTER_ROLE on the clone
        bytes32 minterRole = clone.MINTER_ROLE();
        assertTrue(clone.hasRole(minterRole, admin));

        // Admin can mint on the clone
        vm.prank(admin);
        clone.mint(owner, 1 ether);
        assertEq(clone.balanceOf(owner), 1 ether);
    }

    function test_createDeterministic_predicts_and_initializes() public {
        // Prepare initializer calldata
        bytes memory initData = abi.encodeWithSignature("initialize(string,string,address)", "Fluxion", "FLX", admin);

        // Choose a salt (example: based on owner for uniqueness)
        bytes32 salt = keccak256(abi.encodePacked(address(owner), uint256(1)));

        // Predict address using factory helper
        address predicted = factory.predictDeterministicAddress(salt);

        // Deploy deterministic clone and ensure address matches prediction
        address cloneAddr = factory.createDeterministic(salt, initData);
        assertEq(predicted, cloneAddr);

        Fluxion clone = Fluxion(cloneAddr);

        // Verify initialization happened
        assertEq(clone.name(), "Fluxion");
        assertEq(clone.symbol(), "FLX");

        // Admin should have MINTER_ROLE on the deterministic clone
        bytes32 minterRole = clone.MINTER_ROLE();
        assertTrue(clone.hasRole(minterRole, admin));

        // Admin can mint on the deterministic clone
        vm.prank(admin);
        clone.mint(owner, 2 ether);
        assertEq(clone.balanceOf(owner), 2 ether);
    }
}
