# HenkiNet
- ETH Global 2021 Market Make Final Submission 
- Trivia : 'Henki' is the Finnish Coinage for 'Spirit'

## Summary
First of its kind Reference Implementation of the AAVE Credit Delegation V2 Workflow ERC 1155 Tokens, Token Farms and DAO & AAVE Flash Loan V2 Bonding Curve Integration Architecture on StarkWare StarkEx DEX

## Approach

This project is an attempt to enhance the AAVE Protocol V2 Credit Delegation Workflow and Flash Loans Functionalities. AAVE Credit Delegation V2 Workflow ERC 1155 Tokens, Token Farms, and DAO & AAVE Flash Loan V2 Bonding Curve Integration Architecture on StarkWare StarkEx DEX. Credit Delegation Workflow is enhanced using the ERC 1155 Multi-Function Token Standard. Credit Delegation Workflow is further divided into components such as Loan to Value (LTV), Loan to Cost (LTC), Loan Credit Risk, Loan Credit Score, etc. Each of these components are tokenized as ERC 20 Tokens.  There is a Delegation Farm between Credit Value and Credit Cost tokens created. In addition to these changes to the AAVE CD, this project attempts to distribute the AAVE Batch Flash Loans as a Bonding Curve. This project aims to deploy the AAVE Credit Delegation Workflow as an ERC 1155 Token into the StarkWare StarkEx zkRollup based Decentralised Exchange to speed up the transfer and trade of credit delegation workflow multi tokens in its entirety. 

## Highlights 
- AAVE Credit Delegation V2 Integration to a DAO
- AAVE Credit Delegation Workflow Token as ERC 1155
- AAVE Credit LTV Tokenisation as ERC 20
- AAVE Credit LTC Tokenisation as ERC 20
- AAVE Credit Risk Tokenisation as ERC 20
- AAVE Credit Score Tokenisation as ERC 20
- AAVE Batch Flash Loan Distribution as a Bonding Curve
- AAVE Batch Flash Loan becomes Fusion Loans in a Bonding Curve

## Roadmap
- AAVE Credit Delegation Workflow Token Trade in StarkWare StarkEx
- AAVE Credit LTV Token Trade and Transfer in Starkware StarkEx
- AAVE Credit LTC Token Trade and Transfer in Starkware StarkEx
- AAVE Credit Risk Token Trade and Transfer in Starkware StarkEx
- AAVE Credit Score Token Trade and Transfer in Starkware StarkEx

## Framework

StarkEx is a STARK-powered scalability engine for crypto exchanges. StarkEx uses cryptographic proofs to attest to the validity of a batch of transactions (such as trades and transfers) and updates a commitment to the state of the exchange onchain. StarkEx allows exchanges to provide non-custodial trading at scale with high liquidity and lower costs.

## Modules

1. delegated-dex - StarkEx main contract elements
2. evm-verifier - zkSTARK verifier circuits on EVM
3. delegation-dao - AAVE Credit Delegation DAO
4. fusion-loan - AAVE Flash Loan V2 Distribution
