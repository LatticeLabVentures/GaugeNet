// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;

import {
    IERC20,
    ILendingPool,
    IProtocolDataProvider,
    IStableDebtToken
} from "./Interfaces.sol";
import {SafeERC20} from "./Libraries.sol";
import {DelegationDataTypes} from "./DelegationDataTypes.sol";
import {DelegationVault} from "./DelegationVault.sol";


contract AaveCreditDelegationV2 is DelegationVault {
    using SafeERC20 for IERC20;
    using DelegationDataTypes for DelegationDataTypes.DelegationData;

    address contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    // Track addresses of borrowers (i.e. delegates)
    mapping(address => bool) isBorrower;

    /**
     * @dev -------------------------- TODO ---------------------------------
     * Used to track allowances (loan amounts) for each borrower/delegate
     * ----------------------------------------------------------------------
     */
    // Records the amount (`uint256`) the delegate (`address`) is
    // allowed to withdraw from the delegator's account (`address`).
    mapping(address => mapping(address => uint256)) private borrowerAllowances;

    /**
     * @dev Change these addresses to Mainnet addresses when testing with forked
     * networks in hardhat. Use Kovan when testing UI.
     */
    address constant lendingPoolMainnetAddress =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address constant protocolDataProviderMainnetAddress =
        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    // address constant lendingPoolKovanAddress =
    //     0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe;
    // address constant protocolDataProviderKovanAddress =
    //     0x3c73A5E5785cAC854D468F727c606C07488a29D6;

    ILendingPool constant lendingPool =
        ILendingPool(address(lendingPoolMainnetAddress));
    IProtocolDataProvider constant dataProvider =
        IProtocolDataProvider(address(protocolDataProviderMainnetAddress));
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // ~~~~~~~~~~~~~~~~~~~~~~  Delegation logic events  ~~~~~~~~~~~~~~~~~~~~~~~~
    /**
     * @dev Emitted when a delegation is created.
     * @param asset The address of the asset used in the delegation.
     * @param delegator The address of the creditor.
     * @param delegate The address of the borrower.
     * @param collateralDeposit The delegator's collateral deposit amount.
     * @param creditLine The amount of credit delegated to the borrower.
     * @dev -------------------------- TODO --------------------------------
     * MUST CHECK FOR WHETHER STABLE OR VARIABLE TOKEN
     * param _interestRateMode stable = 1, variable = 2
     * ---------------------------------------------------------------------
     * @param debt The debt this borrower owes to the delegator
     * @param isApproved Does this delegation have an approved borrower?
     * @param hasFullyRepayed Has the borrower repayed their loan?
     * @param hasWithdrawn Has the delegator withdrawn their deposit?
     * @param createdAt When this delegation was created.
     */
    event DelegationDataCreated(
        address indexed asset,
        address indexed delegator,
        address delegate,
        uint256 collateralDeposit,
        uint256 creditLine,
        // uint16 interestRateMode,
        uint256 debt,
        bool isApproved,
        bool hasFullyRepayed,
        bool hasWithdrawn,
        uint256 createdAt
    );

    /**
     * @dev Emitted when the state of a delegation is updated.
     * @param asset The address of the asset used in the delegation.
     * @param delegator The address of the creditor.
     * @param delegate The address of borrower with an uncollateralized loan.
     * @param collateralDeposit The delegator's collateral deposit amount.
     * @param creditLine The amount of credit delegated to the borrower.
     * @dev -------------------------- TODO --------------------------------
     * MUST CHECK FOR WHETHER STABLE OR VARIABLE TOKEN
     * param _interestRateMode stable = 1, variable = 2
     * ---------------------------------------------------------------------
     * @param debt The **NEW** debt balance of the borrower that is now owed
     * @param isApproved Does this delegation have an approved borrower?
     * @param hasFullyRepayed Has the borrower repayed their loan?
     * @param hasWithdrawn Has the delegator withdrawn their deposit?
     * @param createdAt When this delegation was created.
     * @param updatedAt When this delegation was updated.
     */
    event DelegationDataUpdated(
        address indexed asset,
        address indexed delegator,
        address delegate,
        uint256 collateralDeposit,
        uint256 creditLine,
        // uint16 interestRateMode,
        uint256 debt, // **NEW** debt balance of the borrower that is now owed
        bool isApproved,
        bool hasFullyRepayed,
        bool hasWithdrawn,
        uint256 createdAt,
        uint256 updatedAt
    );
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // ~~~~~~~~~~~~~~~~~~~~~~~  Core contract events  ~~~~~~~~~~~~~~~~~~~~~~~~~~
    event Deposit(
        address indexed asset,
        address indexed user,
        uint256 depositAmount // == collateralDeposit
    );

    event CreditApproval(
        address indexed delegator,
        address indexed delegate,
        uint256 creditLine,
        address asset // address indexed asset
    );

    event Borrow(
        address indexed delegator,
        address indexed delegate,
        address assetToBorrow, // address indexed assetToBorrow,
        uint256 amountToBorrow,
        uint256 interestRateMode
        // uint16 _referralCode
    );

    event Repayment(
        address indexed delegator,
        address indexed delegate,
        address asset, // address indexed assetToBorrow,
        uint256 repayAmount
    );

    event Withdrawal(
        address indexed delegator,
        address asset, // address indexed assetToBorrow,
        uint256 collateralDeposit
    );

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // ~~~~~~~~~~~~~~~~~~~~  Delegation logic functions  ~~~~~~~~~~~~~~~~~~~~~~~
    /**
     * @dev Initializes a delegation by adding a borrower. Call this function
     *      **AFTER** a delegator has approved a borrower.
     * @param _asset The address of the asset used in the delegation.
     * @param _delegator The address of the creditor.
     * @param _collateralDeposit The delegator's collateral deposit.
     *
     * @dev -------------------------- TODO --------------------------------
     * MUST CHECK FOR WHETHER STABLE OR VARIABLE TOKEN
     * param _interestRateMode stable = 1, variable = 2
     * ---------------------------------------------------------------------
     */
    function initDelegation(
        address _asset,
        address _delegator,
        uint256 _collateralDeposit
    ) internal {
        // Initialize a delegation object.
        DelegationDataTypes.DelegationData storage delegation =
            _delegations[_delegator];

        delegation.asset = _asset;
        delegation.collateralDeposit = _collateralDeposit;
        /**
         * @dev -------------------------- TODO --------------------------------
         * MUST CHECK FOR WHETHER STABLE OR VARIABLE TOKEN
         * ---------------------------------------------------------------------
         */
        // delegation.interestRateMode = _interestRateMode;
        delegation.debt = 0;
        delegation.isApproved = false;
        delegation.hasFullyRepayed = false;
        delegation.hasWithdrawn = false;
        delegation.exists = true;
        // current block timestamp as seconds since unix epoch
        delegation.createdAt = block.timestamp;

        emit DelegationDataCreated(
            delegation.asset,
            _delegator,
            delegation.delegate,
            delegation.collateralDeposit,
            delegation.creditLine,
            // delegation.interestRateMode,
            delegation.debt,
            delegation.isApproved,
            delegation.hasFullyRepayed,
            delegation.hasWithdrawn,
            delegation.createdAt
        );
    }

    /**
     * @dev Add a borrower to the delegation object.
     * @param _delegator The address of the creditor.
     * @param _delegate The address of borrower with an uncollateralized loan.
     * @param _creditLine The borrower's limit of total debt.
     */
    function addBorrower(
        address _delegator,
        address _delegate,
        uint256 _creditLine // uint16 _interestRateMode
    ) internal {
        // Initialize a delegation object.
        DelegationDataTypes.DelegationData storage delegation =
            _delegations[_delegator];

        // Set the borrower address to the `delegate` field of the object.
        delegation.delegate = _delegate;
        delegation.creditLine = _creditLine;
        delegation.isApproved = true;
        delegation.updatedAt = block.timestamp;

        emit DelegationDataUpdated(
            delegation.asset,
            _delegator,
            delegation.delegate,
            delegation.collateralDeposit,
            delegation.creditLine,
            // delegation.interestRateMode,
            delegation.debt,
            delegation.isApproved,
            delegation.hasFullyRepayed,
            delegation.hasWithdrawn,
            delegation.createdAt,
            delegation.updatedAt
        );
    }

    /**
     * @dev Add the debt amount for this delegation.
     * @param _delegator The address of the creditor.
     * @param _amountToBorrow The debt of the delegate is borrowing.
     */
    function addDebt(address _delegator, uint256 _amountToBorrow) internal {
        // Get the delegation for this delegator.
        DelegationDataTypes.DelegationData storage delegation =
            _delegations[_delegator];

        // Set the borrower address to the `delegate` field of the object.
        delegation.debt = _amountToBorrow;
        delegation.updatedAt = block.timestamp;

        emit DelegationDataUpdated(
            delegation.asset,
            _delegator,
            delegation.delegate,
            delegation.collateralDeposit,
            delegation.creditLine,
            // delegation.interestRateMode,
            delegation.debt,
            delegation.isApproved,
            delegation.hasFullyRepayed,
            delegation.hasWithdrawn,
            delegation.createdAt,
            delegation.updatedAt
        );
    }

    /**
     * @dev Add whether the delegation has been repayed in full.
     * @param _delegator The address of the creditor.
     * @param _repayAmount The amount of debt to be repayed.
     */
    function addRepayment(address _delegator, uint256 _repayAmount) internal {
        // Get the delegation for this delegator.
        DelegationDataTypes.DelegationData storage delegation =
            _delegations[_delegator];

        // Set debt owed to new balance.
        delegation.debt = delegation.debt - _repayAmount;

        if (delegation.debt == 0) delegation.hasFullyRepayed == true;

        delegation.updatedAt = block.timestamp;

        emit DelegationDataUpdated(
            delegation.asset,
            _delegator,
            delegation.delegate,
            delegation.collateralDeposit,
            delegation.creditLine,
            // delegation.interestRateMode,
            delegation.debt,
            delegation.isApproved,
            delegation.hasFullyRepayed,
            delegation.hasWithdrawn,
            delegation.createdAt,
            delegation.updatedAt
        );
    }

    /**
     * @dev Add whether the deposit for the delegation has been withdrawn.
     * @param _delegator The address of the creditor.
     */
    function addWithdrawal(address _delegator) internal {
        // Get the delegation for this delegator.
        DelegationDataTypes.DelegationData storage delegation =
            _delegations[_delegator];

        delegation.hasWithdrawn = true;

        emit DelegationDataUpdated(
            delegation.asset,
            _delegator,
            delegation.delegate,
            delegation.collateralDeposit,
            delegation.creditLine,
            // delegation.interestRateMode,
            delegation.debt,
            delegation.isApproved,
            delegation.hasFullyRepayed,
            delegation.hasWithdrawn,
            delegation.createdAt,
            delegation.updatedAt
        );
    }

    /**
     * @dev -------------------------- TODO ---------------------------------
     * Allow a function caller to view all debt owed to one delegator.
     * ----------------------------------------------------------------------
     */
    // function getBorrowerDebtOwedToDelegator(address _delegator)
    //     public
    //     view
    // // address _delegate
    // {
    //     /** @dev This may be costly */
    //     for (uint256 i = 0; i < Creditors[_delegator].length; i++) {
    //         require(
    //             Creditors[_delegator][i].exists,
    //             "This delegation does not yet exist!"
    //         );

    //         if (Creditors[_delegator][i].delegate == _delegate)
    //             return Creditors[_delegator][i].debt;
    //     }
    // }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // ~~~~~~~~~~~~~~~~~~~  Requirement-check functions  ~~~~~~~~~~~~~~~~~~~~~~~

    function checkCaller(address _caller, bool _isDelegator) internal view {
        if (_isDelegator) {
            require(
                !isBorrower[_caller],
                "Only a delegator can call this function!"
            );
        } else {
            require(
                isBorrower[_caller],
                "Only a delegate can call this function!"
            );
        }
    }

    function checkDelegationExistsWithDelegate(
        address _delegator,
        address _delegate
    ) internal view {
        require(
            _delegations[_delegator].exists == true,
            "This delegation does not yet exist!"
        );
        require(
            _delegations[_delegator].delegate == _delegate,
            "A delegation does not yet exist between this delegate and delegator!"
        );
    }

    function checkDelegationExists(address _delegator) internal view {
        require(
            _delegations[_delegator].exists == true,
            "This delegation does not yet exist!"
        );
    }

    function checkDelegateApprovalRequirements(address _delegator)
        internal
        view
    {
        // The current `_delegations` object mapping only allows for 1 delegate
        // per delegator.
        require(
            _delegations[_delegator].isApproved == false,
            "A delegator can only have 1 approved borrower at a time!"
        );
    }

    function checkDelegateBorrowRequirements(
        address _delegator,
        uint256 _amountToBorrowInWei
    ) internal view {
        require(
            _delegations[_delegator].debt == 0,
            "Delegates can only borrow with 0 debt!"
        );
        require(
            _delegations[_delegator].hasFullyRepayed == false,
            "This loan has been fully repayed. \n A new delegation is required to borrow again!"
        );
        require(
            _delegations[_delegator].creditLine <= _amountToBorrowInWei,
            "You can only borrow an amount <= your delegated credit line!"
        );
    }

    function checkLoanRepaymentRequirements(
        address _delegator,
        uint256 _repayAmount
    ) internal view {
        require(
            !_delegations[_delegator].hasFullyRepayed,
            "You cannot repay a loan that is already fully repayed!"
        );
        require(
            _repayAmount <= _delegations[_delegator].debt,
            "You cannot repay more than your total outstanding debt!"
        );
    }

    function checkDelegatorWithdrawalRequirements(address _delegator)
        internal
        view
    {
        require(
            _delegations[_delegator].hasWithdrawn == false,
            "You have already withdrawn the collateral for this delegation!"
        );
        require(
            _delegations[_delegator].debt == 0,
            "There is still an outstanding debt for this delegation!"
        );
    }

    // function checkOutstandingDebtRequirements() internal {}

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // ~~~~~~~~~~~~~~~~~~~~~~  Core contract functions  ~~~~~~~~~~~~~~~~~~~~~~~~
    /**
     * Deposits collateral into Aave lending pool to enable credit delegation.
     * @notice User must have approved this contract to pull funds with a call
     *         to the `setCanPullFundsFromDelegator()` function above.
     * @param _asset                     The asset to be deposited as collateral.
     * @param _depositAmount             The amount to be deposited as collateral.
     * @param _canPullFundsFromDelegator Boolean value set by user on UI.
     */
    function depositCollateral(
        address _asset,
        uint256 _depositAmount,
        bool _canPullFundsFromDelegator // Ensure that this value is set client-side
    ) public {
        address delegator;
        delegator = msg.sender;

        // Only a delegator can deposit collateral!
        checkCaller(delegator, true);

        // Boolean value is set by calling `setCanPullFundsFromCaller()`
        if (_canPullFundsFromDelegator) {
            IERC20(_asset).safeTransferFrom(
                delegator,
                address(this),
                _depositAmount
            );
        }

        // Approve Aave lending pool for deposit, then deposit `_depositAmount`
        IERC20(_asset).safeApprove(address(lendingPool), _depositAmount);
        lendingPool.deposit(_asset, _depositAmount, address(this), 0);

        // Initialize an delegation object.
        initDelegation(_asset, delegator, _depositAmount);

        // Fetch this event client-side
        emit Deposit(_asset, delegator, _depositAmount);
    }

    /**
     * Approves a borrower to take an uncollaterised loan.
     * @param _delegate    The borrower of the funds.
     * @param _creditLine  The amount the borrower is allowed to borrow (i.e.
     *                     their line of credit).
     * @param _asset       The asset they are allowed to borrow.
     */
    function approveBorrower(
        address _delegate,
        uint256 _creditLine,
        address _asset
    ) public {
        address delegator;
        delegator = msg.sender;

        // Only a delegator should be able to approve borrowers!
        checkCaller(delegator, true);
        checkDelegateApprovalRequirements(delegator);

        /**
         * @dev -------------------------- TODO --------------------------------
         * MUST CHECK FOR WHETHER STABLE OR VARIABLE TOKEN
         * ---------------------------------------------------------------------
         */
        (, address stableDebtTokenAddress, ) =
            dataProvider.getReserveTokensAddresses(_asset);
        IStableDebtToken(stableDebtTokenAddress).approveDelegation(
            _delegate,
            _creditLine
        );

        // Track approved borrowers.
        isBorrower[_delegate] = true;

        /**
         * @dev -------------------------- TODO --------------------------------
         * MUST CHECK FOR WHETHER STABLE OR VARIABLE TOKEN
         * ---------------------------------------------------------------------
         */
        // uint16 interestRateMode;
        // if (stableDebtTokenAddress)
        //    interestRateMode = 1;

        addBorrower(delegator, _delegate, _creditLine);

        emit CreditApproval(delegator, _delegate, _creditLine, _asset);
    }

    /**
     * Let a delegate borrow an amount that was lended to them from a
     * delegator.
     * @notice NOTE: this contract holds and manages a delegate's funds on
     *         behalf of them.
     * @param _assetToBorrow         The address for the asset.
     * @param _amountToBorrowInWei   Require <= amount delegated to borrower.
     * @param _interestRateMode      Require == type of debt delegated token
     * @param _referralCode          If no referral code, == `0`
     * @param _delegator             The address of whom the borrower is
     *                               borrowing the collateral deposit from.
     *                               THIS IS REQUIRED!
     */
    function borrow(
        address _assetToBorrow,
        uint256 _amountToBorrowInWei,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _delegator
    ) public {
        address delegate;
        delegate = msg.sender;

        // Only a delegate can borrow from the Aave lending pool!
        checkCaller(delegate, false);
        // Ensure the delegation between this delegator and delegate exists
        checkDelegationExistsWithDelegate(_delegator, delegate);
        checkDelegateBorrowRequirements(_delegator, _amountToBorrowInWei);

        /**
         * @dev Advice from David from Aave:
         * "with credit delegation contracts, make sure you're aware of whom
         * actually gets credited the deposit in the Aave protocol. I.e. it is
         * most likely your contract address, not your msg.sender. So when you
         * borrow onBehalfOf, you should be using your contract address".
         * @notice Borrowed funds are sent to this contract's address, and NOT
         *         sent to the address of the borrower (i.e. delegate).
         */
        lendingPool.borrow(
            _assetToBorrow,
            _amountToBorrowInWei,
            _interestRateMode,
            _referralCode,
            // Previously, was `_delegator`, but this is incorrect! See David's
            // suggestion in the dev comment above.
            address(this)
        );

        // Update the state of the delegation object.
        addDebt(_delegator, _amountToBorrowInWei);

        emit Borrow(
            delegate,
            _delegator,
            _assetToBorrow,
            _amountToBorrowInWei,
            _interestRateMode
        );
    }

    /**
     * Repay an uncollaterised loan (for use by approved borrowers). Approved
     * borrowers must have approved this contract, a priori, with an allowance
     * to transfer the tokens.
     * @param _delegator                The creditor to whom the borrower is
     *                                  repaying a loan for.
     * @param _repayAmount              The amount to repay.
     * @param _asset                    The asset to be repaid.
     * @param _canPullFundsFromDelegate Whether the contract can pull funds from
     *                                  the delegate.
     *
     * @dev -------------------------- TODO ------------------------------------
     * User calling this function must have approved this contract with an
     * allowance to transfer the tokens.
     * -------------------------------------------------------------------------
     *
     * @dev -------------------------- TODO ------------------------------------
     * You should keep internal accounting of borrowers, if your contract
     * will have multiple borrowers.
     * -------------------------------------------------------------------------
     *
     * @dev -------------------------- TODO ------------------------------------
     * How does the borrower get to keep any profits made from using the
     * borrowed funds?
     * -------------------------------------------------------------------------
     */
    function repayBorrower(
        address _delegator,
        uint256 _repayAmount,
        address _asset,
        bool _canPullFundsFromDelegate
    ) public {
        address delegate;
        delegate = msg.sender;

        // Only approved borrowers can repay an uncollateralized loan!
        checkCaller(delegate, false);
        // Ensure the delegation between this delegator and delegate exists
        checkDelegationExistsWithDelegate(_delegator, delegate);
        checkLoanRepaymentRequirements(_delegator, _repayAmount);

        /**
         * @dev -------------------------- TODO --------------------------------
         * When is the `borrowerAllowances` set?
         */
        // if (borrowerAllowances[msg.sender]) {}

        if (_canPullFundsFromDelegate) {
            IERC20(_asset).transferFrom(delegate, address(this), _repayAmount);
        }

        IERC20(_asset).approve(address(lendingPool), _repayAmount);
        lendingPool.repay(_asset, _repayAmount, 1, address(this));

        // Update the state of the delegation object.
        addRepayment(_delegator, _repayAmount);

        emit Repayment(_delegator, delegate, _asset, _repayAmount);
    }

    /**
     * Withdraw all collateral of an underlying asset.
     * @notice There is potential
     * @param _asset The underlying asset to withdraw.
     */
    function withdrawCollateral(address _asset) public {
        address delegator;
        delegator = msg.sender;

        // Only a delegator should be able to withdraw their collateral!
        checkCaller(delegator, true);
        // Ensure the delegation exists
        checkDelegationExists(delegator);
        checkDelegatorWithdrawalRequirements(delegator);
        // checkOutstandingDebtRequirements(delegator)

        // // Only if no outstanding loans delegated
        // (address aTokenAddress, , ) =
        //     dataProvider.getReserveTokensAddresses(_asset);
        // uint256 assetBalance = IERC20(aTokenAddress).balanceOf(address(this));

        // Force the delegator to withdraw their entire collateral deposit.
        uint256 assetBalance = _delegations[delegator].collateralDeposit;

        lendingPool.withdraw(_asset, assetBalance, delegator);

        // Update the state of the delegation object.
        addWithdrawal(delegator);

        emit Withdrawal(delegator, _asset, assetBalance);
    }
}
