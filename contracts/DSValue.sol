import "./DSMath.sol";
import "./ERC20.sol";

pragma solidity ^0.4.26;

contract DSValue is DSMath {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    
    function read() public returns (bytes32) {
        var (wut, has) = peek();
        assert(has);
        return wut;
    }

    function poke(bytes32 wut) {
        val = wut;
        has = true;
    }
}
