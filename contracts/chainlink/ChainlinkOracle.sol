pragma solidity >0.4.18;

import "./Chainlinked.sol";
import "../ERC20.sol";
import "../DSMath.sol";

contract ChainlinkOracle is ChainlinkClient, DSMath {
    uint32 constant private DELAY = 900; // 15 Minutes

    uint128 val;
    uint32 public zzz;
    uint32 public lag;
    address med;
    address link;
    address owed;
    uint128 lval; // Link value
    uint128 pmt = uint128(2 * LINK); // Payment
    uint128 dis = pmt;               // Disbursement
    ERC20 tok;

    uint128 constant private prem = 1100000000000000000; // premium 1.1 (10%)
    
    uint128 constant private turn = 1010000000000000000; // minimum price change 1.01 (1%)

    bool posted;
    bool told;

    constructor(address _med)
        public
    {
        med = _med;
        link = 0x20fE562d797A42Dcb3399062AE9546cd06f63280;
        setChainlinkToken(link);
        setChainlinkOracle(0xc99B3D447826532722E41bc36e644ba3479E4365);
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
    
    function eval() public view
        returns (bytes32)
    {
        return bytes32(uint(lval));
    }

    function push(uint128 amt, ERC20 tok) public {
        tok.transferFrom(msg.sender, address(this), uint256(amt));
    }

    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > lag);
        require(dis < mul(uint(dis), 2));
        require(dis > div(uint(dis), 2));
        ERC20(link).transferFrom(msg.sender, address(this), uint(pmt_));
        pmt = pmt_;
        lag = uint32(now) + DELAY;
        owed = msg.sender;
        tok = tok_;
        told = false;
        posted = false;
        call();
        chec();
    }

    function call() internal {
        zzz = uint32(now + 43200);
    }

    function chec() internal {
        dis = pmt;
    }

    function cur(bytes32 _requestId, uint256 _price) // Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        post(uint128(_price), uint32(now + 43200));
    }
    
    function sup(bytes32 _requestId, uint256 _price) // Supply Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        tell(uint128(_price));
    }

    function post(uint128 val_, uint32 zzz_) internal
    {
        val = val_;
        zzz = zzz_;
        med.call(abi.encodeWithSignature("poke()"));
        posted = true;
        if (told) { ward(); }
    }

    function tell(uint128 lval_) internal {
        if (posted && (lval_ >= wmul(lval, turn) || lval_ <= wdiv(lval, turn))) {
            dis = pmt;
            ward();
        }
        lval = lval_;
        told = true;
    }

    function ward() internal { // Reward
        if (tok.balanceOf(address(this)) >= wmul(wmul(lval, pmt), prem)) {
            tok.transfer(owed, wmul(wmul(lval, pmt), prem));
        }
    }
}