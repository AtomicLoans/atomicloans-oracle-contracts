pragma solidity 0.4.26;

import "./DSMath.sol";
import "./ERC20.sol";
import "./WETH.sol";
import "./UniswapExchangeInterface.sol";

import "./OracleInterface.sol";
import "./MedianizerInterface.sol";

/**
 * @title Atomic Loans Fund Oracles Contract
 * @notice Contract for interfacing with Oracles using only ETH
 * @author Atomic Loans
 */
contract FundOracles is DSMath {
  ERC20 link;
  WETH weth;
  UniswapExchangeInterface uniswapExchange;

  MedianizerInterface med;

  /**
    * @notice Construct a new Fund Oracles contract
    * @param med_ The address of the Medianizer
    * @param link_ The LINK token address
    * @param weth_ The WETH token address
    * @param uniswapExchange_ The address of the LINK to ETH Uniswap Exchange
    */
  constructor(MedianizerInterface med_, ERC20 link_, WETH weth_, UniswapExchangeInterface uniswapExchange_) public {
    med = med_;
    link = link_;
    weth = weth_;
    uniswapExchange = uniswapExchange_;
  }

  /**
    * @notice Determines the last oracle token payment
    * @param oracle_ Index of oracle
    * @return Last payment to oracle in token (LINK for Chainlink, WETH for Oraclize)
    */
  function billWithEth(uint256 oracle_) public view returns (uint256) {
      return OracleInterface(med.oracles(oracle_)).bill();
  }

  /**
    * @notice Determines the payment amount in ETH
    * @param oracle_ Index of oracle
    * @param payment_ Payment amount in tokens (LINK or WETH)
    * @return Amount of ETH to pay in updateWithEth to update Oracle
    */
  function paymentWithEth(uint256 oracle_, uint128 payment_) public view returns(uint256) {
      if (oracle_ < 5) {
          return uniswapExchange.getEthToTokenOutputPrice(payment_);
      } else {
          return uint(payment_);
      }
  }

  /**
    * @notice Update the Oracle using ETH
    * @param oracle_ Index of oracle
    * @param payment_ Payment amount in tokens (LINK or WETH)
    * @param token_ Address of token to receive as a reward for updating Oracle
    */
  function updateWithEth(uint256 oracle_, uint128 payment_, address token_) public payable {
    address oracleAddress = med.oracles(oracle_);
    OracleInterface oracle = OracleInterface(oracleAddress);
    if (oracle_ < 5) {
      // ChainLink Oracle
      link.approve(address(uniswapExchange), uint(payment_));
      uniswapExchange.ethToTokenSwapOutput.value(msg.value)(uint(payment_), now + 300);
      link.approve(oracleAddress, uint(payment_));
      oracle.update(payment_, token_);
    } else {
      // Oraclize Oracle
      weth.deposit.value(msg.value)();
      weth.approve(oracleAddress, uint(payment_));
      oracle.update(payment_, token_);
    }
  }
}
