pragma solidity >= 0.4.22 < 0.5;

import "./oraclizeAPI.sol";
import "./WETH.sol";
import "./DSMath.sol";

contract OraclizeOracle is usingOraclize {    
    uint128 val;
    uint32 public zzz;
    address med;
    WETH weth;
    
    mapping (uint256 => address) indexes;
    mapping (uint256 => uint256) values;
    
    uint256 next = 0;
    uint256 step = 0;
    
    uint256 last = 0;

    constructor(address _med, address _weth)
        public
    {
        med = _med;
        weth = WETH(_weth);
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
    }
    
    function peek() public view
        returns (bytes32,bool)
    {
        return (bytes32(uint(val)), now < zzz);
    }

    function read() public view
        returns (bytes32)
    {
        assert(now < zzz);
        return bytes32(uint(val));
    }

    function post(uint128 val_, uint32 zzz_, address med_) internal
    {
        val = val_;
        zzz = zzz_;
        (bool ret,) = med_.call(abi.encodeWithSignature("poke()"));
        ret;
    }
    
    function ward(uint128 val_) internal {
        if (next < step) {
            
        }
    }
    
    function fund(uint256 val_, address tok_) public {
        require(now > last + 900);
        weth.transferFrom(msg.sender, address(this), val_);
        weth.withdraw(val_);
        values[step] = val_;
        indexes[step] = msg.sender;
        step = add(step, 1);
        last = now;
        update();
    }
    
    function stock(uint256 val_) public {
        require(now > last + 900);
        weth.transferFrom(msg.sender, address(this), val_);
        weth.withdraw(val_);
        last = now;
        update();
    }
    
    function update()
        public
        payable
    {
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://api.pro.coinbase.com/products/BTC-USD/ticker).price");
    }
    
    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) revert();
        uint128 res = uint128(parseInt(result, 18));
        ward(res);
        post(res, uint32(now + 43200), med);
    }
}