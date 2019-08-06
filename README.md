# Atomic Loans Oracle Contracts

[![Build Status](https://travis-ci.org/AtomicLoans/atomicloans-oracle-contracts.svg?branch=master)](https://travis-ci.org/AtomicLoans/atomicloans-oracle-contracts)
[![Coverage Status](https://coveralls.io/repos/github/AtomicLoans/atomicloans-oracle-contracts/badge.svg?branch=fix-coveralls)](https://coveralls.io/github/AtomicLoans/atomicloans-oracle-contracts?branch=fix-coveralls)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](./LICENSE.md)
[![Telegram](https://img.shields.io/badge/chat-on%20telegram-blue.svg)](https://t.me/Atomic_Loans)
[![Greenkeeper badge](https://badges.greenkeeper.io/AtomicLoans/atomicloans-oracle-contracts.svg)](https://greenkeeper.io/)

Loan Contracts

## How to run

### Requirements

- Git
- Node.Js
- Truffle

Steps:

```
git clone https://github.com/AtomicLoans/ethereum-contracts.git
cd ethereum-contracts
npm install
```

Now run the tests:

`truffle test`

## License

MIT

## Glossary

### `Oracle`
```
Actions:

   reward                    Reward rewardee for calling update on oracle
   setAssetPrice             Called by Chainlink or Oraclize to update the asset price (Bitcoin)
   setPaymentTokenPrice      Called by Chainlink to update the payment token price (LINK)


Getters:

   peek                      Return asset price without validating
   read                      Return asset price with validation


Vars:

   assetPrice                Price of asset (Bitcoin)
   assetPriceUpdated         Ture if setAssetPrice is called by Oraclize or Chainlink
   asyncRequests             List of requests for updating the oracle
   disbursement              Equal to payment amount if oracle requirements are satisfied after calling update on the oracle (price changed by at least 1%)
   expiry                    Expiration time when oracle is considered no longer active or reliable (12 hours) 
   payment                   Amount paid by the user to update the oracle
   paymentTokenPrice         The price of the payment token (For Chainlink oracles: LINK)
   paymentTokenPriceUpdated  True if setPaymentTokenPrice is called by Chainlink
   rewardAmount              Amount rewardee receives if there are sufficient tokens after calling update on the oracle and receiving a response from Chainlink or Oraclize
   rewardee                  Address of user that calls update with the intention of receiving a reward
   timeout                   Delay until oracle `update` can be called again
   token                     Token rewardee requests to receive when calling update on the oracle

```


### `Medianizer`
```
Actions:

   compute                   Compute median of oracles
   fund                      Send funds to oracles to be used for reward
   poke                      Recompute the median of the oracles
   setMaxReward              Called by deployer to setMaxReward for Chainlink Oracles (since there is no way to determine cost of call)
   setOracles                Called by deployer once to set oracle addresses


Getters:

   peek                      Return asset price without validating
   read                      Return asset price with validation


Vars:

   assetPrice                Price of asset (Bitcoin_)
   deployer                  Oracle and Medianizer deployer
   hasPrice                  True if asset price valid
   minOraclesRequired        Minimum number of updated oracles required to get valid price
   on                        Oracles set after deployment
   oracles                   List of oracles
   
```
