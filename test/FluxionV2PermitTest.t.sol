// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {Fluxion} from "../src/FluxionV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FluxionPermitTest is Test {
    Fluxion impl;
    Fluxion token;

    address admin;
    uint256 adminPk;

    address owner;
    uint256 ownerPk;
    address spender;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    function setUp() public {
        adminPk = 0xAB;
        admin = vm.addr(adminPk);

        ownerPk = 0x1;
        owner = vm.addr(ownerPk);

        spender = vm.addr(0x2);
        impl = new Fluxion();

        // Initialize calldata (include trustedForwarder param)
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address,address)",
            "Fluxion",
            "FLX",
            admin,
            address(0)
        );

        // Deploy proxy and initialize
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        token = Fluxion(address(proxy));

        // Mint some tokens to owner for demonstration (admin holds MINTER_ROLE)
        vm.prank(admin);
        token.mint(owner, 1_000 ether);
    }

    function test_initial_state() public view {
        assertEq(token.name(), "Fluxion");
        assertEq(token.symbol(), "FLX");
        assertGt(token.balanceOf(owner), 0);
    }

    function test_permit_sets_allowance() public {
        uint256 value = 100 ether;
        uint256 nonce = token.nonces(owner);
        uint256 deadline = block.timestamp + 1 hours;
        uint256 chainId = block.chainid;

        // Compute domain separator inline to reduce local temporaries
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(token.name())),
                keccak256(bytes("1")), // OZ uses "1" as version for permits
                chainId,
                address(token)
            )
        );

        // Compute the struct hash
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
        );

        // Compute the digest
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        // Sign digest with owner's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        // Verify the signature
        token.permit(owner, spender, value, deadline, v, r, s);

        // Check allowance was set
        assertEq(token.allowance(owner, spender), value);

        // Using the allowance: spender transfers tokens (simulate by pranking spender)
        // Ensure spender has no tokens before transfer
        assertEq(token.balanceOf(spender), 0);
        vm.prank(spender);
        assertTrue(token.transferFrom(owner, address(this), value));

        assertEq(token.balanceOf(address(this)), value);
    }
}
