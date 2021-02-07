/**
 * @TODO -----------------------------------------------------------------------
 * "Always code [CONCISELY, CLEARLY, and READABLY] as if the guy who ends up 
 * maintaining your code will be a violent psychopath who knows where you 
 * live." - John Woods
 *-----------------------------------------------------------------------------
 */
import fetch from 'node-fetch'
import { expect } from "chai"
import hre from 'hardhat'
import { Signer } from 'ethers'
import { BigNumber } from '@ethersproject/bignumber'
import { Contract } from '@ethersproject/contracts'
import { JsonRpcSigner } from '@ethersproject/providers'

import { Dai } from '../typechain/contracts/Dai'
import { AToken } from '../typechain/contracts/AToken'

const ETH_URL: string = 'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd'

// Used to later compute ether and wei amounts to the current price of usd.
async function getEtherPrice(_url: string) {
  const json: any = (await fetch(_url)).json()
  return json
}

describe('AaveCreditDelegationV2', () => {
  let aaveCreditDelegationV2: Contract,
    delegator: string, // == contract creator
    delegate: string, // == approved borrower
    contractOwner: string,
    depositorSigner: JsonRpcSigner,
    borrowerSigner: JsonRpcSigner,
    ownerSigner: JsonRpcSigner,
    dai: Dai,
    aDai: AToken,
    currentEthPriceInUSD: number,
    fiveEtherInUSD: number

  const mintAmount: number = 10_000 // in USD
  const depositAmount: number = 2_000 // in USD
  // The deposit-asset 
  const daiAddress: string = '0x6b175474e89094c44da98b954eedeac495271d0f'
  // The interest bearing asset, received 
  const aDaiAddress: string = '0x028171bCA77440897B824Ca71D1c56caC55b68A3'
  // Used to get the balance of the lending pool
  const lendingPoolAddress: string = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9'

  function amountToEther(_amount: number) {
    const amountInEther: number = _amount / currentEthPriceInUSD
    return amountInEther
  }

  function amountToWei(_amount: number) {
    const amountInWei: BigNumber = hre.ethers.utils.parseEther(
      amountToEther(_amount).toString()
    )
    return amountInWei
  }

  before(async () => {
    // Prepare DAI contract interface for CD contract 
    const signer: JsonRpcSigner = hre.ethers.provider.getSigner(0);

    [delegator, delegate, contractOwner] = await hre.ethers.provider.listAccounts()

    depositorSigner = hre.ethers.provider.getSigner(delegator)
    borrowerSigner = hre.ethers.provider.getSigner(delegate)
    ownerSigner = hre.ethers.provider.getSigner(contractOwner)

    currentEthPriceInUSD = (await getEtherPrice(ETH_URL)).ethereum.usd,
      fiveEtherInUSD = 5.0 * currentEthPriceInUSD

    signer.sendTransaction({
      to: delegator,
      value: hre.ethers.utils.parseEther('1')
    })

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [delegator]
    })

    dai = await hre.ethers.getContractAt('IERC20', daiAddress) as Dai
    aDai = await hre.ethers.getContractAt('IERC20', aDaiAddress) as AToken

    const aaveCreditDelegationV2Address: string = hre
      .ethers.utils.getContractAddress({
        from: delegator,
        nonce: (await hre.ethers.provider.getTransactionCount(delegator)) + 1
      })

    // Approve credit delegation contract for transfers later
    await dai.approve(
      aaveCreditDelegationV2Address,
      hre.ethers.utils.parseEther('100')
    )

    // Create CD contract
    const AaveCreditDelegationV2 = await hre.ethers.getContractFactory(
      'AaveCreditDelegationV2'
    )

    aaveCreditDelegationV2 = await AaveCreditDelegationV2.deploy()
    await aaveCreditDelegationV2.deployed()
  })

  /** 
   * ---------------------------------------------------------------------------
   * @dev When delegator doesn't allow the CD contract to pull funds from their
   *      account.
   * @notice PASSES 
   * ---------------------------------------------------------------------------
   */
  describe("deposit collateral with delegator's funds", async () => {
    let balanceBefore: BigNumber,
      cdContract_aDaiBalanceBefore: BigNumber,
      delegatorBalanceBefore: BigNumber,
      balanceBeforeInEther: string,
      cdContract_aDaiBalanceBeforeInEther: string,
      delegatorBalanceBeforeInEther: string,
      canPullFundsFromDelegator: boolean,
      canPullFundsFromDelegate: boolean,
      assetToBorrow: string, // address
      amountToBorrowInWei: BigNumber,
      // Must be of the same type as the debt token that is delegated, i.e. 
      // stable = 1, variable = 2.
      interestRateMode: number,
      // To be implemented later (used for early supportive projects to the Aave
      // ecosystem). If there is no referral code, use `0`.
      referralCode: number

    function setCanPullFundsFromDelegator(_canPull: boolean) {
      canPullFundsFromDelegator = _canPull
    }

    function setCanPullFundsFromDelegate(_canPull: boolean) {
      canPullFundsFromDelegate = _canPull
    }

    before(async () => {
      // DAI balances in wei
      balanceBefore = await dai.balanceOf(delegator),
        delegatorBalanceBefore = await dai.balanceOf(delegator),
        // DAI balances in ether
        balanceBeforeInEther = hre
          .ethers.utils.formatUnits(balanceBefore, 'ether'),
        delegatorBalanceBeforeInEther = hre
          .ethers.utils.formatUnits(delegatorBalanceBefore, 'ether'),
        // aDAI balance in wei
        cdContract_aDaiBalanceBefore = await aDai.balanceOf(
          aaveCreditDelegationV2.address
        ),
        // aDAI balance in ether
        cdContract_aDaiBalanceBeforeInEther = hre
          .ethers.utils.formatUnits(cdContract_aDaiBalanceBefore, 'ether'),
        // Amount to borrow == 1,000 DAI
        amountToBorrowInWei = amountToWei(depositAmount * 0.5)
    })

    /** @notice PASSES */
    it('delegator should hold 5.0 ether worth of DAI before deposit', async () => {
      const balanceInUSD: number =
        parseFloat(balanceBeforeInEther) * currentEthPriceInUSD

      expect(balanceInUSD).to.eq(fiveEtherInUSD)
    })

    /** 
     * Delegator DAI balance before deposit = 8415.650000000001
     * Delegator DAI balance after deposit = 6415.650000000001
     * 
     * @notice PASSES 
     */
    it('delegator should have 2,000 less DAI after depositing collateral', async () => {
      // 1. Delegator approves this contract to pull funds from his/her account.
      setCanPullFundsFromDelegator(true)


      // 2. Delegator then deposits collateral into Aave lending pool.
      await aaveCreditDelegationV2.connect(depositorSigner).depositCollateral(
        daiAddress,
        amountToWei(depositAmount),
        canPullFundsFromDelegator
      )

      const balanceAfter: BigNumber = await dai.balanceOf(delegator)
      const balanceAfterInEther: string = hre
        .ethers.utils.formatUnits(balanceAfter.toString(), 'ether')
      const diff: number =
        parseFloat(balanceBeforeInEther) - parseFloat(balanceAfterInEther)

      expect(
        diff.toFixed(4)
      ).to.eq(
        amountToEther(depositAmount).toFixed(4)
      )
    })

    /** 
     * CD contract DAI balance after deposit = 0
     * CD contract aDAI balance after deposit = 2000
     * 
     * @notice PASSES
     */
    it('CD contract should now hold 2000 aDAI', async () => {
      const newContractBalanceString = (await aDai.balanceOf(
        aaveCreditDelegationV2.address)
      ).toString()
      const newContractBalanceInUSD = parseFloat(hre.ethers.utils.formatUnits(
        newContractBalanceString,
        'ether'
      ))
      const diff: number = (
        newContractBalanceInUSD - parseFloat(cdContract_aDaiBalanceBeforeInEther)
      ) * currentEthPriceInUSD
      const assertionBalance: number = 2000

      expect(diff.toFixed(4)).to.eq(assertionBalance.toFixed(4))
    })

    /** 
     * --Before--:
     * CD contract DAI balance before borrow = 0
     * CD contract aDAI balance before borrow = 2000.0000013156218
     * 
     * --After--:
     * CD contract DAI balance after borrow =  (+1000) 1000
     * CD contract aDAI balance after borrow =  (=) 2000.0000026312434
     * 
     * @dev Borrowing 50% of the delegated credit amount. Borrowed funds sent to
     *      the CD contract's address and NOT to the delegator's address.
     * @notice PASSES 
     */
    it("delegate should borrow 50% of delegator's deposit amount from lending pool", async () => {
      assetToBorrow = daiAddress,
        interestRateMode = 1, // using the DAI stablecoin
        referralCode = 0  // no referral code

      const cdContract_DaiBalanceBefore = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )

      // 1. Delegator approves the delegate for a line of credit,
      //    which is a percentage of the delegator's collateral deposit.
      await aaveCreditDelegationV2.connect(depositorSigner).approveBorrower(
        delegate,
        amountToBorrowInWei,
        daiAddress
      )

      // 2. The delegate borrows against the Aave lending pool using the credit
      //    delegated to them by the delegator.
      await aaveCreditDelegationV2.connect(borrowerSigner).borrow(
        assetToBorrow,
        /** @dev Borrowed funds are sent to the CD contract. */
        amountToBorrowInWei,
        interestRateMode,
        referralCode,
        delegator
      )

      const cdContractBalanceAfterBorrow: BigNumber = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )
      const diff: BigNumber = cdContractBalanceAfterBorrow.sub(
        cdContract_DaiBalanceBefore
      )

      expect(diff.toString()).to.eq(amountToBorrowInWei)
    })

    /** 
     * --Before--:
     * CD contract DAI balance in USD before repayment =  1000
     * CD contract aDAI balance in USD before repayment =  2000.0000026312441
     * Delegator contract DAI balance in USD before repayment =  6457.95
     * Delegator contract aDAI balance in USD before repayment =  0
     * 
     * --After--:
     * CD contract DAI balance in USD after repayment =  (=) 0
     * CD contract aDAI balance in USD after repayment =  (=) 2000.0000039468698
     * Delegator contract DAI balance in USD after repayment =  (=) 6457.95
     * Delegator contract aDAI balance in USD after repayment =  0
     * 
     * @notice PASSES 
     */
    it("delegate should fully repay borrowed funds using CD contract's funds", async () => {
      // 1. Borrower sets `_canPullFundFromDelegate` to false.
      setCanPullFundsFromDelegate(false)

      const cdContract_DaiBalanceBefore = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )

      const assetToRepay: string = daiAddress
      const repayAmount = amountToBorrowInWei

      // 2. Borrower calls function to repay uncollateralized loan.
      await aaveCreditDelegationV2.connect(borrowerSigner).repayBorrower(
        delegator,
        repayAmount,
        assetToRepay,
        canPullFundsFromDelegate
      )

      const cdContractBalanceAfterRepayment: BigNumber = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )
      const diff: BigNumber = cdContract_DaiBalanceBefore.sub(
        cdContractBalanceAfterRepayment
      )

      expect(diff).to.eq(repayAmount)
    })


    /**
     * --Before--:
     * CD contract DAI balance in USD before withdrawal =  0
     * CD contract aDAI balance in USD before withdrawal =  2000.0000039468748
     * Delegator DAI balance in USD before withdrawal =  6457.95
     * Delegator aDAI balance in USD before withdrawal =  0
     * 
     * --After--:
     * CD contract DAI balance in USD after withdrawal =  (=) 0
     * CD contract aDAI balance in USD after withdrawal =  (-2000) 0.00000526256755246156
     * Delegator DAI balance in USD after withdrawal =  (2000) 8457.95
     * Delegator aDAI balance in USD after withdrawal =  0
     * 
     * @notice PASSES
     */
    it('delegator should withdraw their entire collateral deposit', async () => {
      const assetToWithdraw = daiAddress
      const balanceBefore = await dai.balanceOf(delegator)

      await aaveCreditDelegationV2.connect(depositorSigner).withdrawCollateral(
        assetToWithdraw
      )

      const balanceAfter = await dai.balanceOf(delegator)
      const diff = balanceAfter.sub(balanceBefore)

      expect(diff).to.eq(amountToWei(depositAmount))
    })
  })

  /** 
   * ---------------------------------------------------------------------------
   * @dev Test when the delegator sets `canPull` to `false`
   * @notice PASSES
   * ---------------------------------------------------------------------------
   */
  describe("deposit collateral with contract's funds", async () => {
    let balanceBefore: BigNumber,
      cdContract_aDaiBalanceBefore: BigNumber,
      contractDaiBalanceBeforeToSubtract: BigNumber,
      balanceBeforeInEther: string,
      cdContract_aDaiBalanceBeforeInEther: string,
      canPullFundsFromDelegator: boolean,
      canPullFundsFromDelegate: boolean,
      assetToBorrow: string, // address
      // Must be equal to or less than amount delegated.
      amountToBorrowInWei: BigNumber,
      // Must be of the same type as the debt token that is delegated, i.e. 
      // stable = 1, variable = 2.
      interestRateMode: number,
      // To be implemented later (used for early supportive projects to the Aave
      // ecosystem). If there is no referral code, use `0`.
      referralCode: number

    /**
     * @TODO ------------------------------ TODO -------------------------------
     * Add an easy radio switch directly above or next to the the `deposit` 
     * button (to deposit collateral) which disables the `deposit` button when
     * switched off, and enables deposits when switched on.
     * -------------------------------------------------------------------------
     */
    // This function is called by the UI when the delegator flips the radio 
    // switch, thus allowing for the UI to pull funds from their wallet and 
    // enabling the `deposit` button.
    function setCanPullFundsFromDelegator(_canPull: boolean) {
      canPullFundsFromDelegator = _canPull
    }

    function setCanPullFundsFromDelegate(_canPull: boolean) {
      canPullFundsFromDelegate = _canPull
    }

    before(async () => {
      contractDaiBalanceBeforeToSubtract = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )

      // Send 3.0 ether worth of DAI to CD contract
      await dai.transfer(
        aaveCreditDelegationV2.address,
        hre.ethers.utils.parseEther('3')
      )

      // DAI balances in wei
      balanceBefore = await dai.balanceOf(aaveCreditDelegationV2.address),
        // aDAI balance in wei
        cdContract_aDaiBalanceBefore = await aDai.balanceOf(
          aaveCreditDelegationV2.address
        ),
        // DAI balances in ether
        balanceBeforeInEther = hre
          .ethers.utils.formatUnits(balanceBefore, 'ether'),
        // aDAI balance in ether
        cdContract_aDaiBalanceBeforeInEther = hre
          .ethers.utils.formatUnits(cdContract_aDaiBalanceBefore, 'ether'),
        // Amount to borrow == 1,000 DAI
        amountToBorrowInWei = amountToWei(depositAmount * 0.5)
    })

    /** @notice PASSES */
    it('contract should now hold 3.0 ether worth of DAI, after sending DAI to contract', async () => {
      const balanceAfterReceivingDAI: BigNumber = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )
      const threeEther: BigNumber = hre.ethers.utils.parseEther('3')
      const balance: BigNumber = balanceAfterReceivingDAI.sub(
        contractDaiBalanceBeforeToSubtract
      )

      expect(balance).to.equal(threeEther)
    })

    /** @notice PASSES */
    it('contract should have 2,000 less DAI after depositing collateral', async () => {
      // 1. Delegator denies this contract to pull funds from his/her account,
      //    in effect, telling the contract to use funds held within it.
      setCanPullFundsFromDelegator(false)

      // 2. Delegator then clicks `deposit` button
      await aaveCreditDelegationV2.connect(depositorSigner).depositCollateral(
        daiAddress,
        amountToWei(depositAmount),
        canPullFundsFromDelegator
      )

      const balanceAfter: BigNumber = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )
      const balanceAfterInEther: string = hre
        .ethers.utils.formatUnits(balanceAfter.toString(), 'ether')
      const diff: number =
        parseFloat(balanceBeforeInEther) - parseFloat(balanceAfterInEther)

      expect(
        diff.toFixed(4)
      ).to.eq(
        amountToEther(depositAmount).toFixed(4)
      )
    })

    /** @notice PASSES */
    it('CD contract should now hold 2000 aDAI', async () => {
      const newContractBalanceString = (await aDai.balanceOf(
        aaveCreditDelegationV2.address)
      ).toString()
      const newContractBalanceInUSD = parseFloat(hre.ethers.utils.formatUnits(
        newContractBalanceString,
        'ether'
      ))
      const diff: number = (
        newContractBalanceInUSD - parseFloat(cdContract_aDaiBalanceBeforeInEther)
      ) * currentEthPriceInUSD
      const assertionBalance: number = 2000

      expect(diff.toFixed(4)).to.eq(assertionBalance.toFixed(4))
    })

    /** 
     * --Before--:
     * CD contract DAI balance before borrow = 0
     * CD contract aDAI balance before borrow = 2000.0000013156218
     * 
     * --After--:
     * CD contract DAI balance after borrow =  (+1000) 1000
     * CD contract aDAI balance after borrow =  (=) 2000.0000026312434
     * 
     * @dev Borrowing 50% of the delegated credit amount. Borrowed funds sent to
     *      the CD contract's address and NOT to the delegator's address.
     * @notice PASSES 
     */
    it("delegate should borrow 50% of delegator's deposit amount from lending pool", async () => {
      assetToBorrow = daiAddress,
        interestRateMode = 1, // using the DAI stablecoin
        referralCode = 0  // no referral code

      const cdContract_DaiBalanceBefore = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )

      // 1. Delegator approves the delegate for a line of credit,
      //    which is a percentage of the delegator's collateral deposit.
      await aaveCreditDelegationV2.connect(depositorSigner).approveBorrower(
        delegate,
        amountToBorrowInWei,
        daiAddress
      )

      // 2. The delegate borrows against the Aave lending pool using the credit
      //    delegated to them by the delegator.
      await aaveCreditDelegationV2.connect(borrowerSigner).borrow(
        assetToBorrow,
        /** @dev Borrowed funds are sent to the CD contract. */
        amountToBorrowInWei,
        interestRateMode,
        referralCode,
        delegator
      )

      const cdContractBalanceAfterBorrow: BigNumber = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )
      const diff: BigNumber = cdContractBalanceAfterBorrow.sub(
        cdContract_DaiBalanceBefore
      )

      expect(diff.toString()).to.eq(amountToBorrowInWei)
    })

    /** 
     * --Before--:
     * CD contract DAI balance in USD before repayment =  1000
     * CD contract aDAI balance in USD before repayment =  2000.0000026312441
     * Delegator contract DAI balance in USD before repayment =  6457.95
     * Delegator contract aDAI balance in USD before repayment =  0
     * 
     * --After--:
     * CD contract DAI balance in USD after repayment =  (=) 0
     * CD contract aDAI balance in USD after repayment =  (=) 2000.0000039468698
     * Delegator contract DAI balance in USD after repayment =  (=) 6457.95
     * Delegator contract aDAI balance in USD after repayment =  0
     * 
     * @notice PASSES 
     */
    it("delegate should fully repay borrowed funds using CD contract's funds", async () => {
      // 1. Borrower sets `_canPullFundFromDelegate` to false.
      setCanPullFundsFromDelegate(false)

      const cdContract_DaiBalanceBefore = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )

      const assetToRepay: string = daiAddress
      const repayAmount = amountToBorrowInWei

      // 2. Borrower calls function to repay uncollateralized loan.
      await aaveCreditDelegationV2.connect(borrowerSigner).repayBorrower(
        delegator,
        repayAmount,
        assetToRepay,
        canPullFundsFromDelegate
      )

      const cdContractBalanceAfterRepayment: BigNumber = await dai.balanceOf(
        aaveCreditDelegationV2.address
      )
      const diff: BigNumber = cdContract_DaiBalanceBefore.sub(
        cdContractBalanceAfterRepayment
      )

      expect(diff).to.eq(repayAmount)
    })


    /**
     * --Before--:
     * CD contract DAI balance in USD before withdrawal =  0
     * CD contract aDAI balance in USD before withdrawal =  2000.0000039468748
     * Delegator DAI balance in USD before withdrawal =  6457.95
     * Delegator aDAI balance in USD before withdrawal =  0
     * 
     * --After--:
     * CD contract DAI balance in USD after withdrawal =  (=) 0
     * CD contract aDAI balance in USD after withdrawal =  (-2000) 0.00000526256755246156
     * Delegator DAI balance in USD after withdrawal =  (2000) 8457.95
     * Delegator aDAI balance in USD after withdrawal =  0
     * 
     * @notice PASSES
     */
    it('delegator should withdraw their entire collateral deposit', async () => {
      const assetToWithdraw = daiAddress
      const balanceBefore = await dai.balanceOf(delegator)

      await aaveCreditDelegationV2.connect(depositorSigner).withdrawCollateral(
        assetToWithdraw
      )

      const balanceAfter = await dai.balanceOf(delegator)
      const diff = balanceAfter.sub(balanceBefore)

      expect(diff).to.eq(amountToWei(depositAmount))
    })
  })
})
