pragma solidity 0.4.26;

// import "./OraclizeAPI.sol"; // MAINNET
import "../test/OraclizeAPITesting.sol"; // TESTING
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
    
    function update(uint128 payment_, ERC20 token_) { // payment
        require(uint32(now) > timeout);
        require(payment_ == oraclize_getPrice("URL"));
        require(weth.transferFrom(msg.sender, address(this), uint(payment_)));
        bytes32 queryId = getAssetPrice(payment_);
        setPaymentTokenPrice(queryId, uint128(medm.read()));
        asyncRequests[queryId].rewardee = msg.sender;
        asyncRequests[queryId].payment  = payment_;
        asyncRequests[queryId].token    = token_;
        timeout = uint32(now) + DELAY;
    }

    function getAssetPrice(uint128 payment) internal returns (bytes32);
    
    function __callback(bytes32 myid, string result, bytes proof) {
        require(msg.sender == oraclize_cbAddress());
        require(asyncRequests[myid].rewardee != address(0));
        uint128 res = uint128(parseInt(result, 18));
        setAssetPrice(myid, res, uint32(now + 43200));
    }

    function setMaxReward(uint256 maxReward_) public {
        require(msg.sender == address(med));
    }
}
