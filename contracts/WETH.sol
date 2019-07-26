pragma solidity ^0.4.26;

import './ERC20.sol';

contract WETH is ERC20 {
    function deposit() public payable;
    function withdraw(uint wad) public;
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
}