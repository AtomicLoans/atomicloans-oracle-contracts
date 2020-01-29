pragma solidity ^0.4.26;

import "./DSMath.sol";
import "./ERC20.sol";
import "./WETH.sol";
import "./UniswapExchangeInterface.sol";

import "./OracleInterface.sol";
import "./MedianizerInterface.sol";

contract FundOracles is DSMath {
  ERC20 link;
  WETH weth;
  UniswapExchangeInterface uniswapExchange;

  MedianizerInterface med;

  constructor(MedianizerInterface med_, ERC20 link_, WETH weth_, UniswapExchangeInterface uniswapExchange_) public {
    med = med_;
    link = link_;
    weth = weth_;
    uniswapExchange = uniswapExchange_;
  }
  
  function billWithEth(uint256 oracle_) public view returns (uint256) {
      return OracleInterface(med.oracles(oracle_)).bill();
  }
  
  function paymentWithEth(uint256 oracle_, uint128 payment_) public view returns(uint256) {
      if (oracle_ < 5) {
          return uniswapExchange.getEthToTokenOutputPrice(payment_);
      } else {
          return uint(payment_);
      }
  }

  function updateWithEth(uint256 oracle_, uint128 payment_, address token_) public payable {
    address oracleAddress = med.oracles(oracle_);
    OracleInterface oracle = OracleInterface(oracleAddress);
    if (oracle_ < 5) {
      // ChainLink Oracle
      uint256 ethAmt = msg.value;
      link.approve(address(uniswapExchange), uint(payment_));
      uint256 ethSold = uniswapExchange.ethToTokenSwapOutput.value(msg.value)(uint(payment_), now + 300);
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
