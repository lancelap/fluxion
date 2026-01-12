// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title Simple Factory using OpenZeppelin Clones
/// @notice Factory that holds an implementation address and can deploy clones.
/// - createClone(bytes calldata initData) -> clones implementation and calls initializer
/// - createDeterministic(bytes32 salt, bytes calldata initData) -> cloneDeterministic + init
contract Factory {
    using Address for address;

    /// @notice Implementation contract that will be cloned
    address public implementation;

    /// @notice Emitted when a clone is created and initialized
    event CloneCreated(address indexed clone, address indexed implementation, bytes initData);

    /// @param _implementation Address of the implementation to be cloned
    constructor(address _implementation) {
        require(_implementation != address(0), "Factory: zero implementation");
        implementation = _implementation;
    }

    /// @notice Deploys a minimal proxy clone and calls initializer on it.
    /// @param initData Calldata for the initializer (e.g. encoded initialize(name, symbol, admin))
    /// @return clone Address of the deployed clone
    function createClone(bytes calldata initData) external payable returns (address clone) {
        require(implementation != address(0), "Factory: implementation not set");

        clone = Clones.clone(implementation);

        // Initialize the clone. Forward msg.value to support payable initializers.
        // Reverts if the initialization call fails.
        Address.functionCallWithValue(clone, initData, msg.value);

        emit CloneCreated(clone, implementation, initData);
    }

    /// @notice Deploys a deterministic minimal proxy clone (CREATE2) and calls initializer on it.
    /// @param salt Salt used for deterministic deployment
    /// @param initData Calldata for the initializer
    /// @return clone Address of the deployed clone
    function createDeterministic(bytes32 salt, bytes calldata initData) external payable returns (address clone) {
        require(implementation != address(0), "Factory: implementation not set");

        clone = Clones.cloneDeterministic(implementation, salt);

        // Initialize the clone. Forward msg.value to support payable initializers.
        Address.functionCallWithValue(clone, initData, msg.value);

        emit CloneCreated(clone, implementation, initData);
    }

    /// @notice Helper to predict the deterministic address for a given salt (uses this factory as deployer)
    /// @param salt Salt used for deterministic deployment
    /// @return predicted predicted address
    function predictDeterministicAddress(bytes32 salt) external view returns (address predicted) {
        predicted = Clones.predictDeterministicAddress(implementation, salt, address(this));
    }
}
