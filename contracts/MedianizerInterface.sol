pragma solidity 0.4.26;

import "./ERC20.sol";

interface MedianizerInterface {
    function oracles(uint256) public view returns (address);
    function peek() public view returns (bytes32, bool);
    function read() public returns (bytes32);
    function poke() public;
    function poke(bytes32) public;
    function fund (uint256 amount, ERC20 token) public;
}
