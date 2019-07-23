pragma solidity ^0.4.26;

import "./DSMath.sol";
import "./DSValue.sol";

contract Oracle is DSMath {
    uint32  constant public DELAY = 900; // 15 Minutes
    uint128 constant public prem = 1100000000000000000; // premium 1.1 (10%)
    uint128 constant public turn = 1010000000000000000; // minimum price change 1.01 (1%)

    DSValue med;
    DSValue medm;
    ERC20   tok;

    uint32  public zzz;
    uint32  public lag;
    address        owed;             // Address owed reward
    uint128        val;                     
    uint128 public lval;             // Link value
    uint128        pmt;              // Payment
    uint128        dis;
    uint256        gain;
    bool           posted;           // Currency price posted
    bool           told;             // Payment currency price posted

    function peek() public view
        returns (bytes32,bool)
    {
        return (bytes32(uint(val)), now < zzz);
    }

    function read() public view
        returns (bytes32)
    {
        assert(now < zzz);
        return bytes32(uint(val));
    }
    
    function bill() public view returns (uint256) {
        return pmt;
    }
    
    function call()
        internal
    {
        zzz = uint32(now + 43200);
    }
    
    function chec()
        internal
    {
        tell(uint128(medm.read()));
    }

    function post(uint128 val_, uint32 zzz_) internal
    {
        if (val_ >= wmul(val, turn) || val_ <= wdiv(val, turn)) { dis = pmt; }
        val = val_;
        zzz = zzz_;
        med.poke();
        posted = true;
        if (told) { ward(); }
    }

    function tell(uint128 lval_) internal {
        lval = lval_;
        told = true;
        if (posted) { ward(); }
    }

    function ward() internal { // Reward
        gain = wmul(wmul(lval, dis), prem);
        if (tok.balanceOf(address(this)) >= gain && dis > 0) {
            require(tok.transfer(owed, gain));
        }
    }

    function setMax(uint256 maxr_) public {
        require(msg.sender == address(med));
    }
}
