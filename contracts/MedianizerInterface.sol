import "./ERC20.sol";

pragma solidity ^0.4.26;

contract MedianizerInterface {
    function oracles(uint256) public view returns (address);
    function peek() public view returns (bytes32, bool);
    function read() public returns (bytes32);
    function poke() public;
    function poke(bytes32) public;
    function fund (uint256 amount, ERC20 token) public;
}
