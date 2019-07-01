pragma solidity >0.4.18;

import "./Chainlinked.sol";
import "./ERC20.sol";

contract BraveNewCoinChainlinkOracle is ChainlinkClient {
    uint32 constant private DELAY = 900; // 15 Minutes

    uint128 val;
    uint32 public zzz;
    uint32 public lag;
    address med;
    address link;
    address owed;
    
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    bytes32 constant UINT256_MUL_JOB = bytes32("e695b2fcabdc4d90b07b97406c88bf8b");

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

    function post(uint128 val_, uint32 zzz_) internal
    {
        val = val_;
        zzz = zzz_;
        (bool ret,) = med_.call(abi.encodeWithSignature("poke()"));
        ret;
    }

    function pack() {
        require(uint32(now) > lag);
        ERC20(link).transferFrom(msg.sender, 2 * ORACLE_PAYMENT);
        lag = uint32(now) + DELAY;
        owed = msg.sender;
        call();
        chec();
    }

    function call()
        public
    {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.fulfill.selector);
        req.add("endpoint", "mwa-historic");
        req.add("coin", "btc");
        req.add("market", "usd");
        req.add("copyPath", "data.-1.1");
        req.addInt("times", 1000000000000000000);
        sendChainlinkRequest(req, ORACLE_PAYMENT);
    }

    function chec() public {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.fulfill.selector);
        req.add("endpoint", "mwa-historic");
        req.add("coin", "link");
        req.add("market", "usd");
        req.add("copyPath", "data.-1.1");
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