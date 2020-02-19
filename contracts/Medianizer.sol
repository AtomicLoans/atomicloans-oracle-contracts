pragma solidity 0.4.26;

import "./ERC20.sol";
import "./Oracle.sol";
import "./DSMath.sol";

/**
 * @title Atomic Loans Medianizer Contract
 * @author Atomic Loans
 */
contract Medianizer is DSMath {
    bool    hasPrice;
    bytes32 assetPrice;
    uint256 public minOraclesRequired = 5;
    bool on;
    address deployer;

    uint256 constant public MIN_ORACLIZE_GAS_LIMIT = 200000;
    uint256 constant public MAX_ORACLIZE_GAS_LIMIT = 1000000;

    Oracle[] public oracles;

    event Fund(uint256 amount_, ERC20 token_);

    event Poke(bytes32 assetPrice, bool hasPrice);

    /**
     * @notice Construct a new Medianizer
     */
    constructor() public {
    	deployer = msg.sender;
    }

    // NOTE: THE FOLLOWING FUNCTION CAN ONLY BE CALLED BY THE DEPLOYER OF THE
    //       CONTRACT ONCE. THIS IS TO ALLOW FOR MEDIANIZER AND ORACLE
    //       CONTRACTS TO BE DEPLOYED SEPARATELY (DUE TO GAS LIMIT RESTRICTIONS).
    //       IF YOU ARE USING THIS CONTRACT, ENSURE THAT THESE FUNCTIONS HAVE
    //       ALREADY BEEN CALLED BEFORE USING.
    // ======================================================================

    /**
     * @notice Sets Oracle contracts
     * @param addrs Addresses of Oracle contracts
     */
    function setOracles(address[10] addrs) public {
        require(!on, "Funds.setOracles: Oracles already set");
        require(msg.sender == deployer, "Funds.setOracles: msg.sender isn't deployer");
        oracles.push(Oracle(addrs[0]));
        oracles.push(Oracle(addrs[1]));
        oracles.push(Oracle(addrs[2]));
        oracles.push(Oracle(addrs[3]));
        oracles.push(Oracle(addrs[4]));
        oracles.push(Oracle(addrs[5]));
        oracles.push(Oracle(addrs[6]));
        oracles.push(Oracle(addrs[7]));
        oracles.push(Oracle(addrs[8]));
        oracles.push(Oracle(addrs[9]));
    	on = true;
    }
    // ======================================================================

    // NOTE: THE FOLLOWING FUNCTION ALLOW THE MAX REWARD TO BE MODIFIED BY THE
    //       DEPLOYER, SINCE CHAINLINK ORACLES DON'T HAVE A SET PAYMENT
    //       AND CHAINLINK OPERATORS CAN INDEPENDENTLY SET THEIR OWN LINK PRICES.
    //       ADDITIONALLY EVEN IF THE MAX REWARD IS SET TO ZERO, THE ORACLES
    //       CAN STILL BE UPDATED.
    // ======================================================================

    /**
     * @notice Sets Max Reward for Chainlink Contracts
     * @param maxReward_ Max Reward amount that can be awarded for updating Chainlink Oracle
     */
    function setMaxReward(uint256 maxReward_) public {
        require(on, "Funds.setMaxReward: Oracles not set");
        require(msg.sender == deployer, "Funds.setMaxReward: msg.sender isn't deployer");
        oracles[0].setMaxReward(maxReward_);
        oracles[1].setMaxReward(maxReward_);
        oracles[2].setMaxReward(maxReward_);
        oracles[3].setMaxReward(maxReward_);
        oracles[4].setMaxReward(maxReward_);
        oracles[5].setMaxReward(maxReward_);
        oracles[6].setMaxReward(maxReward_);
        oracles[7].setMaxReward(maxReward_);
        oracles[8].setMaxReward(maxReward_);
        oracles[9].setMaxReward(maxReward_);
    }
    // ======================================================================

    // NOTE: THE FOLLOWING FUNCTION ALLOW THE GAS LIMIT TO BE MODIFIED BY THE
    //       DEPLOYER, SINCE ORACLIZE ORACLES HAVE A MINIMUM GAS LIMIT OF
    //       200,000 AND THERE COULD BE CASES WHERE THERE IS NOT ENOUGH GAS TO
    //       COVER UPDATING THE PRICE. THE GAS LIMIT CAN BE CHANGED BETWEEN
    //       A MINIMUM OF 200,000 GAS AND A MAXIMUM OF 1,000,000 GAS.
    // ======================================================================

    /**
     * @notice Sets Gas Limit for Oraclize Contracts
     * @param gasLimit_ Gas Limit that Oraclize will use when updating the contracts
     */
    function setGasLimit(uint256 gasLimit_) public {
        require(on, "Funds.setGasLimit: Oracles not set");
        require(msg.sender == deployer, "Funds.setGasLimit: msg.sender isn't deployer");
        require(gasLimit_ >= MIN_ORACLIZE_GAS_LIMIT, "Funds.setGasLimit: gasLimit_ cannot be less than min oraclize gas limit");
        require(gasLimit_ <= MAX_ORACLIZE_GAS_LIMIT, "Funds.setGasLimit: gasLimit_ cannot be greater than max oraclize gas limit");
        oracles[0].setGasLimit(gasLimit_);
        oracles[1].setGasLimit(gasLimit_);
        oracles[2].setGasLimit(gasLimit_);
        oracles[3].setGasLimit(gasLimit_);
        oracles[4].setGasLimit(gasLimit_);
        oracles[5].setGasLimit(gasLimit_);
        oracles[6].setGasLimit(gasLimit_);
        oracles[7].setGasLimit(gasLimit_);
        oracles[8].setGasLimit(gasLimit_);
        oracles[9].setGasLimit(gasLimit_);
    }
    // ======================================================================

    /**
     * @notice Return Medianizer price without asserting
     */
    function peek() public view returns (bytes32, bool) {
        return (assetPrice,hasPrice);
    }

    /**
     * @notice Return Medianizer price and assert that value has been set recently
     * @dev Reverts if price is not set or has not been set within expiry for enough Oracles
     */
    function read() public returns (bytes32) {
        (assetPrice, hasPrice) = peek();
        assert(hasPrice);
        return assetPrice;
    }

    /**
     * @notice Add funds to oracle reserve that is used to compensate users to updating oracles
     * @param amount_ Amount of ERC20 stablecoin token to fund
     * @param token_ Address of ERC20 stablecoin token
     */
    function fund(uint256 amount_, ERC20 token_) public {
        require(amount_ < 2**128-1, "Medianizer.fund: amount is greater than max uint128"); // Ensure amount fits in uint128
        for (uint256 i = 0; i < oracles.length; i++) {
            require(
                token_.transferFrom(msg.sender, address(oracles[i]), uint256(hdiv(uint128(amount_), uint128(oracles.length)))),
                "Medianizer.fund: failed to transfer tokens to oracles"
            );
        }

        emit Fund(amount_, token_);
    }

    /**
     * @notice Compute and set Medianizer price
     */
    function poke() public {
        poke(0);
    }

    /**
     * @notice Compute and set Medianizer price
     */
    function poke(bytes32) public {
        (assetPrice, hasPrice) = compute();

        emit Poke(assetPrice, hasPrice);
    }

    /**
     * @notice Compute Medianizer price based on current price of oracles
     * @return Asset price and bool true if price is set
     */
    function compute() public view returns (bytes32, bool) {
        bytes32 wut;
        bool wuz;
        bytes32[] memory wuts = new bytes32[](oracles.length);
        uint256 ctr = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            if (address(oracles[i]) != 0) {
                (wut, wuz) = oracles[i].peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint256 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint256 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < minOraclesRequired) return (assetPrice, false);

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(wuts[(ctr / 2) - 1]);
            uint128 val2 = uint128(wuts[ctr / 2]);
            value = bytes32((val1 + val2) / 2);
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }
}
