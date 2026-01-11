// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Fluxion is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // UUPSUpgradeable override to include access control
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

   function initialize(string memory name_, string memory symbol_, address admin_) public initializer {
    // Initialize contracts
    __ERC20_init(name_, symbol_);
    __ERC20Permit_init(name_);
    __AccessControlEnumerable_init();

    // Grant roles
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(MINTER_ROLE, admin_);
    _grantRole(UPGRADER_ROLE, admin_);

    // init mint some tokens to admin
    _mint(admin_, 1_000_000 * 10 ** decimals());
   }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // UUPS authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // Reserved storage space to allow for layout changes in the future
    uint256[50] private __gap;
}
