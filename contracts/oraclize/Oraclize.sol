pragma solidity ^0.4.26;

// import "./OraclizeAPI.sol"; // MAINNET
import "./OraclizeAPITesting.sol"; // TESTING
import "../Oracle.sol";
import "../WETH.sol";

contract Oraclize is usingOraclize, Oracle {
    WETH weth;
    Medianizer medm;

    constructor(Medianizer med_, Medianizer medm_, WETH weth_)
        public
    {
        med = med_;
        medm = medm_;
        weth = weth_;
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
        bytes32 queryId = call(pmt_);
        tell(queryId, uint128(medm.read()));
        areqs[queryId].owed = msg.sender;
        areqs[queryId].pmt  = pmt_;
        areqs[queryId].tok  = tok_;
        lag = uint32(now) + DELAY;
    }

    function call(uint128 pmt) internal returns (bytes32);
    
    function __callback(bytes32 myid, string result, bytes proof) {
        require(msg.sender == oraclize_cbAddress());
        require(areqs[myid].owed != address(0));
        uint128 res = uint128(parseInt(result, 18));
        post(myid, res, uint32(now + 43200));
    }

    function setMax(uint256 maxr_) public {
        require(msg.sender == address(med));
    }
}
