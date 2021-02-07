# GaugeNet

## Concept
ERC 1155 Multi Token Standard based Forward Flashloan Marketplace with AAVE Credit Delegation Workflows Deployed in ZKP based StarkEx Scalablity Engine.

## Progress 
Fine Tuned AAVE Lending Pools and AAVE Credit Delegation. Integrated AAVE Lending Pools and AAVE Credit Delegation Workflows into the Scalable StarkEx. Created LendingPoolRegistry and LendingPoolAdaptorFactRegistry in the StarkEx. 

## Framework

StarkEx is a STARK-powered scalability engine for crypto exchanges. StarkEx uses cryptographic
proofs to attest to the validity of a batch of transactions (such as trades and transfers)
and updates a commitment to the state of the exchange onchain. 

StarkEx allows exchanges to provide non-custodial trading at scale with high liquidity and lower
costs.

## Modules

1. scalable-dex - StarkEx main contract elements
2. evm-verifier - Cryptographic STARK verifier elements
