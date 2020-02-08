import 'chainlink/node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

pragma solidity 0.4.26;

contract ExampleLinkCoin is StandardToken {
  string public name = "ExampleLinkCoin"; 
  string public symbol = "LINK";
  uint public decimals = 18;

  constructor () public {
    _mint(msg.sender, 12020000000000000000000);
  }

  function _mint(address account, uint256 value) internal {
    totalSupply_ = totalSupply_.add(value);
    balances[account] = balances[account].add(value);
    emit Transfer(address(0), account, value);
  }
}