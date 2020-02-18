pragma solidity 0.4.26;

// import "./OraclizeAPI.sol"; // MAINNET
import "../test/OraclizeAPITesting.sol"; // TESTING
import "../Oracle.sol";
import "../WETH.sol";

contract Oraclize is usingOraclize, Oracle {
    WETH weth;
    MedianizerInterface medm;

    uint256 public gasLimit = 200000;

    constructor(MedianizerInterface med_, MedianizerInterface medm_, WETH weth_)
        public
    {
        require(address(med_) != address(0), "Oraclize.constructor: med_ is zero address");
        require(address(medm_) != address(0), "Oraclize.constructor: medm_ is zero address");
        require(address(weth_) != address(0), "Oraclize.constructor: weth_ is zero address");
        med = med_;
        medm = medm_;
        weth = weth_;
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
    }

    function () public payable { }

    function bill() public view returns (uint256) {
        return oraclize_getPrice("URL", gasLimit);
    }

    function update(uint128 payment_, ERC20 token_) public { // payment
        require(uint32(now) > timeout, "Oraclize.update: now is less than timeout");
        require(payment_ == oraclize_getPrice("URL", gasLimit), "Oraclize.update: payment doesn't equal oraclize_getPrice");
        require(weth.transferFrom(msg.sender, address(this), uint(payment_)), "Oraclize.update: failed to transfer weth from msg.sender");
        bytes32 queryId = getAssetPrice(payment_);
        setPaymentTokenPrice(queryId, uint128(medm.read()));
        asyncRequests[queryId].rewardee = msg.sender;
        asyncRequests[queryId].payment = payment_;
        asyncRequests[queryId].token = token_;
        timeout = uint32(now) + DELAY;
    }

    function getAssetPrice(uint128) internal returns (bytes32);

    function __callback(bytes32 queryId, string result_, bytes) public {
        require(msg.sender == oraclize_cbAddress(), "Oraclize.__callback: msg.sender isn't Oraclize address");
        require(asyncRequests[queryId].rewardee != address(0), "Oraclize.__callback: rewardee is not zero address");
        uint128 res = uint128(parseInt(result_, 18));
        setAssetPrice(queryId, res, uint32(now + 43200));
    }

    function setMaxReward(uint256) public {
        require(msg.sender == address(med), "Oraclize.setMaxReward: msg.sender isn't medianizer address");
    }

    function setGasLimit(uint256 gasLimit_) public {
        require(msg.sender == address(med), "Oraclize.setGasLimit: msg.sender isn't medianizer address");
        gasLimit = gasLimit_;
    }
}
