import "./ERC20.sol";
import "./DSValue.sol";

pragma solidity ^0.4.8;

contract Medianizer is DSValue {
    mapping (address => bool)    public tokas;  // Is ERC20 Token Approved
    mapping (bytes12 => address) public values;
    mapping (address => bytes12) public indexes;
    bytes12 public next = 0x1;

    uint96 public min = 0x5;

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
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) internal {
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
    	DSValue(values[bytes12(1)]).setMax(maxr_);
    	DSValue(values[bytes12(2)]).setMax(maxr_);
    	DSValue(values[bytes12(3)]).setMax(maxr_);
    	DSValue(values[bytes12(4)]).setMax(maxr_);
    	DSValue(values[bytes12(5)]).setMax(maxr_);
    }

    function push (uint256 amt, ERC20 tok) {
      if (tokas[address(tok)] == false) {
        tokas[address(tok)] = true;
        for (uint96 j = 1; j < uint96(next); j++) {
          require(tok.approve(values[bytes12(j)], 2**256-1));
        }
        tokas[address(tok)] = true;
      }
      for (uint96 i = 1; i < uint96(next); i++) {
      require(tok.transferFrom(msg.sender, values[bytes12(i)], uint(div(uint128(amt), uint128(next) - 1))));
      }
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) {
        (val, has) = compute();
    }

    function compute() constant returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != 0) {
                var (wut, wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
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