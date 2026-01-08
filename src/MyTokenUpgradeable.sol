// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title MyTokenUpgradeable
/// @notice ERC20 token with ERC2612 (permit), UUPS upgradability and meta-tx support (ERC2771 trusted forwarder)
/// - Uses OpenZeppelin Upgradeable contracts
/// - Access control via AccessControlUpgradeable (OPERATOR_ROLE for mint/burn)
/// - Owner (OwnableUpgradeable) authorized to perform upgrades
/// - Supports ERC2612 via ERC20PermitUpgradeable
/// @dev Be careful to initialize all inherited modules via initializer
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyTokenUpgradeable is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Initialize the token implementation (use via proxy)
    /// @param name_ token name
    /// @param symbol_ token symbol
    /// @param owner_ owner address (will be DEFAULT_ADMIN_ROLE and upgrade controller)
    /// @param trustedForwarder trusted forwarder for meta-transactions (address(0) if none)
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address owner_,
        address trustedForwarder
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __AccessControl_init();
        __Ownable_init();
        __ERC2771Context_init(trustedForwarder);
        __UUPSUpgradeable_init();

        // set owner and admin role
        _transferOwnership(owner_);
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    /// @notice Mint tokens to an account (operator-only)
    function mint(address to, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        _mint(to, amount);
    }

    /// @notice Burn tokens from caller (operator may burnFrom by allowance)
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /// @notice Operator can burn from an account (uses allowance)
    function burnFrom(address account, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /// @notice Update trusted forwarder (only owner)
    function setTrustedForwarder(address newForwarder) external onlyOwner {
        _setTrustedForwarder(newForwarder);
    }

    /// @dev The UUPS authorization: restrict upgrades to owner
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- Overrides required by Solidity for multiple inheritance ---

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    // If you add interfaces that require supportsInterface, AccessControl provides it.
    // No need to override supportsInterface here unless you implement additional interfaces.
}