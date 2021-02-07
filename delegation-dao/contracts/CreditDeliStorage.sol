// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;

import {DelegationDataTypes} from "./DelegationDataTypes.sol";

/**
 * @dev This contract is analogous to Aave's `LendingPoolStorage`. Everything
 * other than core variable mappings and other storage variables must be
 * contained within `DelegationLogic.sol`.
 */
contract CreditDeliStorage {
    using DelegationDataTypes for DelegationDataTypes.DelegationData;

    /**
     * @dev --------------------------  TODO  ----------------------------------
     * NOTE: the mapping below only allows for 1 delegate per delegator. You
     *       will likely need another mapping to allow for multiple delegates
     *       per delegator.
     *
     * Liam Horne's advice from Discord,
     * "You may want `(delegator, delegate) => boolean` mapping.
     * Basically, a mapping of every possible edge on the graph to true or false
     * -------------------------------  TODO  ----------------------------------
     */
    // Records the approved delegate of each delegator.
    mapping(address => DelegationDataTypes.DelegationData)
        internal _delegations;

    // List of available delegations, structured as a mapping for gas savings
    // reasons
    mapping(uint256 => address) internal _delegationsList;

    // uint256 internal _delegationsCount;
    // bool internal _paused;
}
