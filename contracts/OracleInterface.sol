pragma solidity 0.4.26;

interface OracleInterface {
  function bill() external view returns (uint256);
  function update(uint128 payment_, address token_) external;
}
