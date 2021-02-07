# HenkiNet

## Summary
Delegation DEX and DAO for AAVE Flash Loan Curves and ERC 11555 Credit Collective Tokens on StarkEx

## Highlights 
- AAVE Credit Delegation V2 Integration to a DAO
- AAVE Credit Delegation Workflow Token as ERC 1155
- AAVE Credit LTV Tokenisation as ERC 20
- AAVE Credit LTC Tokenisation as ERC 20
- AAVE Credit Risk Tokenisation as ERC 20
- AAVE Credit Score Tokenisation as ERC 20
- AAVE Batch Flash Loan Distribution as a Bonding Curve
- AAVE Batch Flash Loan becomes Fusion Loans in a Bonding Curve
- AAVE Credit Delegation Workflow Token Trade in StarkWare StarkEx
- AAVE Credit LTV Token Trade and Transfer in Starkware StarkEx


## Framework

StarkEx is a STARK-powered scalability engine for crypto exchanges. StarkEx uses cryptographic proofs to attest to the validity of a batch of transactions (such as trades and transfers) and updates a commitment to the state of the exchange onchain. StarkEx allows exchanges to provide non-custodial trading at scale with high liquidity and lower
costs.

## Modules

1. delegated-dex - StarkEx main contract elements
2. evm-verifier - zkSTARK verifier circuits on EVM
3. delegation-dao - AAVE Credit Delegation DAO
