pragma solidity 0.4.26;

import "./ERC20.sol";

interface MedianizerInterface {
    function peek() external view returns (bytes32, bool);
    function read() external returns (bytes32);
    function poke() external;
    function poke(bytes32) external;
    function fund (uint256, ERC20) external;
}
