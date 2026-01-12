// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @custom:oz-upgrades-from src/Fluxion.sol:Fluxion
contract Fluxion is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Trusted forwarder address for meta-transactions (ERC2771-like)
    address private _trustedForwarder;

    // UUPSUpgradeable override to include access control
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, address admin_, address trustedForwarder)
        public
        initializer
    {
        // Initialize contracts
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __AccessControlEnumerable_init();

        // Set trusted forwarder for meta-transactions
        _trustedForwarder = trustedForwarder;

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(UPGRADER_ROLE, admin_);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // UUPS authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /// Returns true if `forwarder` is the trusted forwarder for this contract.
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    // Override _msgSender/_msgData to support MinimalForwarder-style meta-transactions.
    function _msgSender() internal view override(ContextUpgradeable) returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The last 20 bytes of calldata should contain the real sender address.
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, sub(calldatasize(), 20), 20)
                sender := shr(96, mload(ptr))
            }
        } else {
            sender = msg.sender;
        }
    }

    function _msgData() internal view override(ContextUpgradeable) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    // Reserved storage space to allow for layout changes in the future
    // reduced by one slot because we added _trustedForwarder
    uint256[49] private __gap;
}
