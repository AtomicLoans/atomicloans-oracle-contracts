pragma solidity >0.4.18;

import "./oraclizeAPI.sol";
import "../WETH.sol";
import "../DSMath.sol";
import "../DSValue.sol";

contract CoinbaseOraclizeOracle is usingOraclize, DSMath {
    uint32 constant private DELAY = 900; // 15 Minutes

    uint128 val;
    uint32 public zzz;
    uint32 public lag;
    DSValue med;
    DSValue medm;
    WETH weth;
    address link;
    address owed;
    uint128 lval; // Link value
    uint128 pmt = uint128(bill());        // Payment
    uint128 dis = pmt;           // Disbursement
    ERC20 tok;
    
    uint256 gain;
    uint256 maxr; // Max reward

    uint128 constant private prem = 1100000000000000000; // premium 1.1 (10%)
    
    uint128 constant private turn = 1010000000000000000; // minimum price change 1.01 (1%)

    bool posted;
    bool told;

    constructor(DSValue med_, DSValue medm_, WETH weth_)
        public
    {
        med = med_;
        medm = medm_;
        weth = weth_;
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
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
    
    function eval() public view
        returns (bytes32)
    {
        return bytes32(uint(lval));
    }

    function push(uint128 amt, ERC20 tok) public {
        tok.transferFrom(msg.sender, address(this), uint256(amt));
    }
    
    function bill() public view returns (uint256) {
        return oraclize_getPrice("URL");
    }
    
    function pack(ERC20 tok_) {
        pack(uint128(bill()), tok_);   
    }
    
    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > lag);
        require(pmt_ == oraclize_getPrice("URL"));
        weth.transferFrom(msg.sender, address(this), uint(pmt_));
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
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://api.pro.coinbase.com/products/BTC-USD/ticker).price");
    }
    
    function chec()
        internal
    {
        tell(uint128(medm.read()));
    }
    
    function __callback(bytes32 myid, string result, bytes proof) {
        require(msg.sender == oraclize_cbAddress());
        uint128 res = uint128(parseInt(result, 18));
        post(res, uint32(now + 43200));
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
        if (tok.balanceOf(address(this)) >= wmul(wmul(lval, dis), prem) && dis > 0) {
            tok.transfer(owed, wmul(wmul(lval, dis), prem));
        }
    }
    
    function setMax(uint256 maxr_) public {
        require(msg.sender == address(med));
        maxr = maxr_;
    }
}