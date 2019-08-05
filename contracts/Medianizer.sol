import "./ERC20.sol";
import "./Oracle.sol";
import "./DSMath.sol";

pragma solidity ^0.4.26;

contract Medianizer is DSMath {
    bool    has;
    bytes32 val;
    uint256 public min = 5;
    bool on;
    address deployer;

    Oracle[] public values;

    constructor() {
    	deployer = msg.sender;
    }

    function setOracles(address[10] addrs) {
    	require(!on);
        require(msg.sender == deployer);
        values.push(Oracle(addrs[0]));
        values.push(Oracle(addrs[1]));
        values.push(Oracle(addrs[2]));
        values.push(Oracle(addrs[3]));
        values.push(Oracle(addrs[4]));
        values.push(Oracle(addrs[5]));
        values.push(Oracle(addrs[6]));
        values.push(Oracle(addrs[7]));
        values.push(Oracle(addrs[8]));
        values.push(Oracle(addrs[9]));
    	on = true;
    }

    function setMaxReward(uint256 maxReward_) {
    	require(on);
    	require(msg.sender == deployer);
        values[0].setMaxReward(maxReward_);
        values[1].setMaxReward(maxReward_);
        values[2].setMaxReward(maxReward_);
        values[3].setMaxReward(maxReward_);
        values[4].setMaxReward(maxReward_);
        values[5].setMaxReward(maxReward_);
        values[6].setMaxReward(maxReward_);
        values[7].setMaxReward(maxReward_);
        values[8].setMaxReward(maxReward_);
        values[9].setMaxReward(maxReward_);
    }

    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }

    function read() public returns (bytes32) {
        var (wut, has) = peek();
        assert(has);
        return wut;
    }

    function push (uint256 amt, ERC20 tok) {
      for (uint256 i = 0; i < values.length; i++) {
        require(tok.transferFrom(msg.sender, address(values[i]), uint(div(uint128(amt), uint128(values.length)))));
      }
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) {
        (val, has) = compute();
    }

    function compute() public returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](values.length);
        uint256 ctr = 0;
        for (uint256 i = 0; i < values.length; i++) {
            if (address(values[i]) != 0) {
                var (wut, wuz) = values[i].peek();
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

        if (ctr < min) return (val, false);

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
