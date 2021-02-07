// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;

import {DelegationDataTypes} from "./DelegationDataTypes.sol";

contract DelegationVault {
    using DelegationDataTypes for DelegationDataTypes.DelegationData;

    // Records the approved delegate of each delegator.
    mapping(address => DelegationDataTypes.DelegationData)
        internal _delegations;

    // List of available delegations, structured as a mapping for gas savings
    // reasons
    mapping(uint256 => address) internal _delegationsList;

    // uint256 internal _delegationsCount;
    // bool internal _paused;
}
