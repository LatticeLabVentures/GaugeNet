// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;

/**
 * @dev "IM" stands for "IterableMapping"
 * @dev -------------------------- TODO ---------------------------------
 * This library is analogous to Aave's `DataTypes`. Everything other than the
 * `struct`s and `enum`s to be contained within the `CreditDeliStorage`
 * contract.
 * ----------------------------------------------------------------------
 */
library DelegationDataTypes {
    /**
     * @dev Structs taken from IterableMapping example in Solidity docs:
     * https://docs.soliditylang.org/en/v0.8.0/types.html#operators-involving-lvalues
     */
    // struct KeyFlag {
    //     uint256 key;
    //     bool isDelegator;
    // }

    struct DelegationData {
        address asset; // Address of the asset used in the delegation
        address delegate; // Address of borrower with an uncollateralized loan
        uint256 collateralDeposit; // Delegator's collateral deposit amount
        uint256 creditLine; // Bororwer's limit of total debt
        uint256 debt; // Amount this borrower owes to the delegator
        bool isApproved; // Does this delegation have an approved borrower?
        bool hasFullyRepayed; // Has the borrower repayed their loan?
        bool hasWithdrawn; // Has the delegator withdrawn their deposit?
        bool exists; // Does this delegation exist?
        uint256 createdAt; // When this delegation was created
        uint256 updatedAt; // When this delegation was updated
    }

    /**
     * @dev -------------------------- TODO ---------------------------------
     * Add the proper functions for this CD iterable mapping under its respective
     * library
     * ----------------------------------------------------------------------
     */
    // struct IMCreditDelegation {
    //     // Records the approved delegates of each delegator.
    //     mapping(address => CreditDelegation[]) Creditors;
    //     KeyFlag[] keys;
    //     uint256 size;
    // }

    // enum InterestRateMode {NONE, STABLE, VARIABLE};
}
