pragma solidity 0.4.26;

// import "./OraclizeAPI.sol"; // MAINNET
import "../test/OraclizeAPITesting.sol"; // TESTING
import "../Oracle.sol";
import "../WETH.sol";

/**
 * @title Atomic Loans Oraclize Contract
 * @author Atomic Loans
 */
contract Oraclize is usingOraclize, Oracle {
    WETH weth;
    MedianizerInterface medm;

    uint256 public gasLimit = 200000;

    /**
     * @notice Construct a new Oraclize Oracle
     * @param med_ The address of the Medianizer
     * @param medm_ The address of the MakerDAO Medianizer
     * @param weth_ The WETH token address
     */
    constructor(MedianizerInterface med_, MedianizerInterface medm_, WETH weth_) public {
        require(address(med_) != address(0), "Oraclize.constructor: med_ is zero address");
        require(address(medm_) != address(0), "Oraclize.constructor: medm_ is zero address");
        require(address(weth_) != address(0), "Oraclize.constructor: weth_ is zero address");
        med = med_;
        medm = medm_;
        weth = weth_;
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
    }

    function () public payable { }

    /**
     * @notice Gets the payment needed to update the Oracle
     * @return Oraclize price for query in wei
     */
    function bill() public view returns (uint256) {
        return oraclize_getPrice("URL", gasLimit);
    }

    /**
     * @notice Sender redeems WETH in exchange for Updating the Oracle and receiving stablecoin tokens
     * @param payment_ The amount of WETH used as payment for Oraclize
     * @param token_ The address of the ERC20 stablecoin to receive as a reward
     */
    function update(uint128 payment_, ERC20 token_) public {
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

    /**
     * @notice Creates request for Oraclize to get the BTC price
     */
    function getAssetPrice(uint128) internal returns (bytes32);

    /**
     * @notice Oraclize returns result from API price query
     * @param queryId ID of the query from Oraclize
     * @param result_ API price returned from Oraclize query
     */
    function __callback(bytes32 queryId, string result_, bytes) public {
        require(msg.sender == oraclize_cbAddress(), "Oraclize.__callback: msg.sender isn't Oraclize address");
        require(asyncRequests[queryId].rewardee != address(0), "Oraclize.__callback: rewardee is not zero address");
        uint128 res = uint128(parseInt(result_, 18));
        setAssetPrice(queryId, res, uint32(now + 43200));
    }

    /**
     * @notice Sets Max Reward for Chainlink Contracts
     */
    function setMaxReward(uint256) public {
        require(msg.sender == address(med), "Oraclize.setMaxReward: msg.sender isn't medianizer address");
    }

    /**
     * @notice Sets Gas Limit for Oraclize Contracts
     * @param gasLimit_ Gas Limit that Oraclize will use when updating the contracts
     */
    function setGasLimit(uint256 gasLimit_) public {
        require(msg.sender == address(med), "Oraclize.setGasLimit: msg.sender isn't medianizer address");
        gasLimit = gasLimit_;
    }
}
