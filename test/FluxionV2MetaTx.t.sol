// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {Fluxion} from "../src/FluxionV2.sol";
import {MinimalForwarder} from "../src/MinimalForwarder.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FluxionMetaTxTest is Test {
    Fluxion impl;
    Fluxion token;
    MinimalForwarder forwarder;

    address admin;
    uint256 adminPk;

    address owner;
    uint256 ownerPk;
    address spender;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant FORWARD_REQUEST_TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );

    function setUp() public {
        adminPk = 0xAB;
        admin = vm.addr(adminPk);

        ownerPk = 0x1;
        owner = vm.addr(ownerPk);

        spender = vm.addr(0x2);

        impl = new Fluxion();
        forwarder = new MinimalForwarder();

        // initialize via proxy and pass trustedForwarder
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address,address)",
            "Fluxion",
            "FLX",
            admin,
            address(forwarder)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        token = Fluxion(address(proxy));

        // Mint some tokens to owner (admin has MINTER_ROLE)
        vm.prank(admin);
        token.mint(owner, 1_000 ether);
    }

    function test_meta_approve_via_forwarder() public {
        uint256 value = 100 ether;
        bytes memory data = abi.encodeWithSelector(token.approve.selector, spender, value);
        uint256 nonce = forwarder.getNonce(owner);
        uint256 gas = 1_000_000;
        uint256 chainId = block.chainid;

        // Domain separator matching MinimalForwarder EIP712("MinimalForwarder","0.0.1")
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("MinimalForwarder")),
                keccak256(bytes("0.0.1")),
                chainId,
                address(forwarder)
            )
        );

        // Struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                FORWARD_REQUEST_TYPEHASH,
                owner,
                address(token),
                uint256(0), // value
                gas,
                nonce,
                keccak256(data)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // Sign with owner's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Build request and execute via forwarder (relayer can be any address)
        MinimalForwarder.ForwardRequest memory req = MinimalForwarder.ForwardRequest({
            from: owner,
            to: address(token),
            value: 0,
            gas: gas,
            nonce: nonce,
            data: data
        });

        // Use a relayer address
        address relayer = vm.addr(0xDE);
        vm.prank(relayer);
        (bool success, ) = forwarder.execute(req, signature);
        require(success, "Forwarder execute failed");

        // After execution, approval should be set as if owner called approve(spender, value)
        assertEq(token.allowance(owner, spender), value);
    }
}