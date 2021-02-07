# 🥪 aave-credit-deli-core 🥪

Core smart contracts for the [`aave-credit-deli-interface`](https://github.com/platocrat/aave-credit-dele-interface).

## 📄 Description

### Glossary

* credit delegation == CD
* delegator == depositor
* delegate == borrower

### Features

#### What `AaveCreditDelegationV2.sol` allows

1. **1-to-1 delegations, _only_**
    This means that each delegator (i.e. depositor) can have only 1 delegate (i.e. borrower) at a time.
    > NOTE: YES, there will be 1-to-many delegations in the near future! I am still working on this 😉.

2. **Linear delegations**
    A linear delegation is defined by the progression of a delegation between a delegator and a delegate.

    A _"linear" progression_ means that the delegation starts, progresses, and ends in the following order:
        1. **Delegator deposits collateral** into the Aave lending pool.
        2. Once a deposit has been made, **the delegator approves 1 delegate** for a line of credit (i.e. the maximum amount the delegate is allowed to borrow).
        3. Once the delegate is approved to borrow, the **delegate borrows an amount** from their credit line. This borrow action in this step is equivalent to the delegate taking on debt.
        4. Once the delegate has debt, the **delegate repays an amount** of their debt. A delegate (borrower) can make as many repayments on their debt until the debt of the uncollateralized loan is fully repayed. The repayment action in this step is equivalent to paying off a portion (or all) of the debt.
        5. Once the delegate's debt has been fully repayed, the **delegator withdraws their entire collateral deposit**. A withdrawal of the entire deposit is _forced_ when a delegator (that has a delegation that exists) calls the function in this step. No partial withdrawals are possible.

    > NOTE: Partial withdrawals may be enabled in the near future 🙂. However, if enabled for a delegation, that delegation would be _"non-linear"_ and would operate along a different control flow.

#### What this contract does NOT allow

1. **1-to-many delegations**
    This is being actively worked on. If the community places greater priority over this feature, then this will be added sooner.

2. **Non-linear delegations**
    A non-linear delegation is any other possible delegation that has a progression _different_ than a linear delegation. See the "Linear delegations" section above for more information.

3. **Delegate ownership of borrowed funds**
    When an approved delegate borrows funds, the borrowed funds are immediately sent to the CD contract. This eliminates counterparty (i.e. credit) risk that a delegator has when delegating credit.

    The borrowed funds are held and managed by the CD contract, `AaveCreditDelegationV2.sol`. Again, this is meant to protect delegators from the risk of default by potential approved borrowers.

## 🎞 Demo

Screenshots:

Gifs:

Site:

## 👥 Contributors

[@platocrat](https://github.com/platocrat/)
