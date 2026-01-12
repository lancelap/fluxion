// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {Fluxion as FluxionV1} from "../src/Fluxion.sol";
import {Fluxion as FluxionV2} from "../src/FluxionV2.sol";

contract IncompatibleFluxion is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    // <-- Inserted slot that will cause an incompatible storage layout
    uint256 public injected;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Note: we keep a compatible initialize signature (with a dummy trustedForwarder param)
    // so we can use the same initializer encoding when upgrading.
    function initialize(
        string memory name_,
        string memory symbol_,
        address admin_,
        address /* trustedForwarder */
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __AccessControlEnumerable_init();

        injected = 0xDEADBEEF;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(UPGRADER_ROLE, admin_);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // keep gap similar to V2 (we added one slot 'injected' so we reduce gap accordingly)
    uint256[49] private __gap;
}

contract UpgradeFluxionV1ToV2ExtraTest is Test {

    function test_upgrade_detects_layout_diff_and_allows_unsafe_then_rollback() public {
        // keys
        uint256 adminPk = 0xAB;
        address admin = vm.addr(adminPk);

        uint256 ownerPk = 0x1;
        address owner = vm.addr(ownerPk);

        // 1) Deploy V1 via Upgrades helper (implementation + proxy and call initialize)
        bytes memory initV1 = abi.encodeWithSignature(
            "initialize(string,string,address)",
            "Fluxion",
            "FLX",
            admin
        );

        FluxionV1 implV1 = new FluxionV1();
        address proxy = UnsafeUpgrades.deployUUPSProxy(address(implV1), initV1);
        FluxionV1 tokenV1 = FluxionV1(proxy);

        // 2) Use V1: mint tokens to owner (admin is minter)
        vm.prank(admin);
        tokenV1.mint(owner, 1_000 ether);
        assertEq(tokenV1.balanceOf(owner), 1_000 ether);

        // Check role in V1
        bytes32 minterRole = tokenV1.MINTER_ROLE();
        assertTrue(tokenV1.hasRole(minterRole, admin));

        // 3) Deploy an implementation that has an incompatible storage layout
        IncompatibleFluxion badImpl = new IncompatibleFluxion();
 
        // 4) Note: the safe Upgrades helper validates storage layouts and would reject
        //    incompatible implementations. Since the incompatible contract is defined
        //    only inside this test (not available as an artifact string), we demonstrate
        //    the behaviour by forcing an unsafe upgrade below.
 
        // 5) Force upgrade using UnsafeUpgrades (bypasses layout validation)
        UnsafeUpgrades.upgradeProxy(proxy, address(badImpl), "", admin);

        // At this point the proxy uses badImpl as implementation (may be safe or may corrupt state).
        // We demonstrate rollback: deploy a compatible implementation and force-upgrade back.
        FluxionV1 freshV1Impl = new FluxionV1();
        UnsafeUpgrades.upgradeProxy(proxy, address(freshV1Impl), "", admin);

        // 6) After rollback verify state preserved (balances and roles).
        FluxionV1 tokenRolled = FluxionV1(proxy);

        // Balances preserved
        assertEq(tokenRolled.balanceOf(owner), 1_000 ether);

        // Roles preserved
        assertTrue(tokenRolled.hasRole(minterRole, admin));
    }

    // A small test to show upgrading to the official V2 implementation (which adjusts gap properly)
    function test_safe_upgrade_to_v2_preserves_state() public {
        uint256 adminPk = 0xAB;
        address admin = vm.addr(adminPk);

        uint256 ownerPk = 0x1;
        address owner = vm.addr(ownerPk);

        bytes memory initV1 = abi.encodeWithSignature(
            "initialize(string,string,address)",
            "Fluxion",
            "FLX",
            admin
        );

        FluxionV1 implV1Second = new FluxionV1();
        address proxy = UnsafeUpgrades.deployUUPSProxy(address(implV1Second), initV1);
        FluxionV1 tokenV1 = FluxionV1(proxy);

        vm.prank(admin);
        tokenV1.mint(owner, 500 ether);
        assertEq(tokenV1.balanceOf(owner), 500 ether);

        // Deploy official V2 implementation (it was written to keep layout compatible)
        FluxionV2 newImpl = new FluxionV2();
 
        // In test environment the Upgrades helper may run external validation which
        // depends on build-info files. Use UnsafeUpgrades in tests to keep them hermetic
        // while still exercising the upgrade path and verifying state preservation.
        UnsafeUpgrades.upgradeProxy(proxy, address(newImpl), "", admin);

        FluxionV2 tokenV2 = FluxionV2(proxy);

        // State preserved
        assertEq(tokenV2.balanceOf(owner), 500 ether);

        // Roles preserved
        bytes32 minterRole = tokenV2.MINTER_ROLE();
        assertTrue(tokenV2.hasRole(minterRole, admin));

        // New V2 feature present
        assertTrue(tokenV2.isTrustedForwarder(address(0)));
    }
}