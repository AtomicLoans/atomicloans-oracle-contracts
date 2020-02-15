pragma solidity 0.4.26;

import "./DSMath.sol";
import "./ERC20.sol";

contract DSValue is DSMath {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }

    function read() public returns (bytes32) {
        bytes32 wut;
        (wut, has) = peek();
        assert(has);
        return wut;
    }

    function poke(bytes32 wut) public {
        val = wut;
        has = true;
    }
}
