pragma solidity ^0.4.26;

import "./OraclizeAPITesting.sol";
import "../Oracle.sol";
import "../WETH.sol";
import "../DSValue.sol";

contract Oraclize is usingOraclize, Oracle {
    WETH weth;

    constructor(DSValue med_, DSValue medm_, WETH weth_)
        public
    {
        med = med_;
        medm = medm_;
        weth = weth_;
        pmt = uint128(bill());
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
    }

    function () public payable { }
    
    function bill() public view returns (uint256) {
        return oraclize_getPrice("URL");
    }
    
    function pack(ERC20 tok_) {
        pack(uint128(bill()), tok_);   
    }
    
    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > lag);
        require(pmt_ == oraclize_getPrice("URL"));
        require(weth.transferFrom(msg.sender, address(this), uint(pmt_)));
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
    
    function __callback(bytes32 myid, string result, bytes proof) {
        require(msg.sender == oraclize_cbAddress());
        uint128 res = uint128(parseInt(result, 18));
        post(res, uint32(now + 43200));
    }
}