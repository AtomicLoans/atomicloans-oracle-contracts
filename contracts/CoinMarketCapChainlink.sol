pragma solidity >0.4.18;

import "./Chainlinked.sol";

contract CoinMarketCapOracle is ChainlinkClient {
    uint128 val;
    uint32 public zzz;
    address med;
    
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    bytes32 constant UINT256_MUL_JOB = bytes32("3fcbda4c30d94f9197fe75bd534f6543");

    constructor(address _med)
        public
    {
        med = _med;
        setChainlinkToken(0x20fE562d797A42Dcb3399062AE9546cd06f63280);
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

    function post(uint128 val_, uint32 zzz_) internal
    {
        val = val_;
        zzz = zzz_;
        (bool ret,) = med_.call(abi.encodeWithSignature("poke()"));
        ret;
    }
    
    function update()
        public
    {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.fulfill.selector);
        req.add("sym", "BTC");
        req.add("convert", "USD");
        string[] memory path = new string[](5);
        path[0] = "data";
        path[1] = "BTC";
        path[2] = "quote";
        path[3] = "USD";
        path[4] = "price";
        req.addStringArray("copyPath", path);
        req.addInt("times", 1000000000000000000);
        sendChainlinkRequest(req, ORACLE_PAYMENT);
    }

    function fulfill(bytes32 _requestId, uint256 _price)
        public
        recordChainlinkFulfillment(_requestId)
    {
        post(uint128(_price), uint32(now + 43200));
    }
}