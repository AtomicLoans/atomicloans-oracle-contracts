pragma solidity ^0.4.26;

import "./DSMath.sol";
import "./ERC20.sol";
import "./Medianizer.sol";

contract Oracle is DSMath {
    uint32  constant public DELAY = 900; // 15 Minutes
    uint128 constant public prem = 1100000000000000000; // premium 1.1 (10%)
    uint128 constant public turn = 1010000000000000000; // minimum price change 1.01 (1%)

    Medianizer med;

    uint32 public zzz;
    uint32 public lag;
    uint128 val;                     
    uint128 public lval;             // Link value
    uint256 gain;

    mapping(bytes32 => Areq) areqs;

    struct Areq {
        address owed;
        uint128 pmt;
        uint128 dis;
        ERC20 tok;
        bool posted;
        bool told;
    }

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

    function push(uint128 amt, ERC20 tok_) public {
        require(tok_.transferFrom(msg.sender, address(this), uint256(amt)));
    }
    
    function post(bytes32 queryId, uint128 val_, uint32 zzz_) internal
    {
        areqs[queryId].dis = 0;
        if (val_ >= wmul(val, turn) || val_ <= wdiv(val, turn)) { areqs[queryId].dis = areqs[queryId].pmt; }
        val = val_;
        zzz = zzz_;
        med.poke();
        areqs[queryId].posted = true;
        if (areqs[queryId].told) { ward(queryId); }
    }

    function tell(bytes32 queryId, uint128 lval_) internal {
        lval = lval_;
        areqs[queryId].told = true;
        if (areqs[queryId].posted) { ward(queryId); }
    }

    function ward(bytes32 queryId) internal { // Reward
        gain = wmul(wmul(lval, areqs[queryId].dis), prem);
        if (areqs[queryId].tok.balanceOf(address(this)) >= gain && areqs[queryId].dis > 0) {
            require(areqs[queryId].tok.transfer(areqs[queryId].owed, gain));
        }
        delete(areqs[queryId]);
    }

    function setMax(uint256 maxr_) public;
}
