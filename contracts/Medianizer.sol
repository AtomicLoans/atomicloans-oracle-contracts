import "./ERC20.sol";
import "./Oracle.sol";
import "./DSMath.sol";

pragma solidity ^0.4.26;

contract Medianizer is DSMath {
    bool    has;
    bytes32 val;

    mapping (bytes32 => address) public values;
    mapping (address => bytes32) public indexes;
    bytes32 public next = 0x1;

    uint256 public min = 0x5;

    bool on;

    address own;

    constructor() {
    	own = msg.sender;
    }

    function set(address[10] addrs) {
    	require(!on);
    	set(addrs[0]);
    	set(addrs[1]);
    	set(addrs[2]);
    	set(addrs[3]);
    	set(addrs[4]);
    	set(addrs[5]);
    	set(addrs[6]);
    	set(addrs[7]);
    	set(addrs[8]);
    	set(addrs[9]);
    	on = true;
    }

    function set(address wat) internal {
        bytes32 nextId = bytes32(uint256(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes32 pos, address wat) internal {
        if (pos == 0x0) throw;

        if (wat != 0 && indexes[wat] != 0) throw;

        indexes[values[pos]] = 0; // Making sure to remove a possible existing address in that position

        if (wat != 0) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMax(uint256 maxr_) {
    	require(on);
    	require(msg.sender == own);
      Oracle(values[bytes32(1)]).setMax(maxr_);
      Oracle(values[bytes32(2)]).setMax(maxr_);
      Oracle(values[bytes32(3)]).setMax(maxr_);
      Oracle(values[bytes32(4)]).setMax(maxr_);
      Oracle(values[bytes32(5)]).setMax(maxr_);
      Oracle(values[bytes32(6)]).setMax(maxr_);
      Oracle(values[bytes32(7)]).setMax(maxr_);
      Oracle(values[bytes32(8)]).setMax(maxr_);
      Oracle(values[bytes32(9)]).setMax(maxr_);
      Oracle(values[bytes32(10)]).setMax(maxr_);
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
      for (uint256 i = 1; i < uint256(next); i++) {
        require(tok.transferFrom(msg.sender, values[bytes32(i)], uint(div(uint128(amt), uint128(next) - 1))));
      }
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) {
        (val, has) = compute();
    }

    function compute() public returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint256(next) - 1);
        uint256 ctr = 0;
        for (uint256 i = 1; i < uint256(next); i++) {
            if (values[bytes32(i)] != 0) {
                var (wut, wuz) = Oracle(values[bytes32(i)]).peek();
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
            value = bytes32(wdiv(hadd(val1, val2), 2 ether));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }
}