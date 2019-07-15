pragma solidity >0.4.18;

import "./DSMath.sol";
import "./DSValue.sol";

contract Oracle is DSMath {
    uint32  constant public DELAY = 900; // 15 Minutes
    uint128 constant public prem = 1100000000000000000; // premium 1.1 (10%)
    uint128 constant public turn = 1010000000000000000; // minimum price change 1.01 (1%)

    DSValue med;
    DSValue medm;
    ERC20   tok;

    uint32 public zzz;
    uint32 public lag;
    address owed;                    // Address owed reward
    uint128 val;                     
    uint128 lval;                    // Link value
    uint128 pmt;                     // Payment
    uint128 dis;
    uint256 gain;
    bool posted;                     // Currency price posted
    bool told;                       // Payment currency price posted

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
    
    function eval() public view
        returns (bytes32)
    {
        return bytes32(uint(lval));
    }

    function push(uint128 amt, ERC20 tok_) public {
        tok_.transferFrom(msg.sender, address(this), uint256(amt));
    }
    
    function bill() public view returns (uint256) {
        return pmt;
    }
    
    function pack(ERC20 tok_) {
        pack(uint128(bill()), tok_);   
    }
    
    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > lag);
        pmt = pmt_;
        dis = 0;
        lag = uint32(now) + DELAY;
        owed = msg.sender;
        tok = tok_;
        told = false;
        posted = false;
        call();
        chec();
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
        med.call(abi.encodeWithSignature("poke()"));
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
            tok.transfer(owed, gain);
        }
    }
}