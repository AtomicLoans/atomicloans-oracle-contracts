import "./BraveNewCoinChainlinkOracle.sol";
import "./CoinbaseOraclizeOracle.sol";
import "./CoinGeckoOraclizeOracle.sol";
import "./CoinMarketCapChainlink.sol";
import "./CoinpaprikaOraclizeOracle.sol";
import "./CryptocompareChainlinkOracle.sol";
import "./KaikoChainlinkOracle.sol";
import "./ERC20.sol";
import "./DSMath.sol";

pragma solidity ^0.4.8;

contract DSValue is DSMath {
    bool    has;
    bytes32 val;
    function peek() constant returns (bytes32, bool) {
        return (val,has);
    }
    function read() constant returns (bytes32) {
        var (wut, has) = peek();
        assert(has);
        return wut;
    }
    function poke(bytes32 wut) {
        val = wut;
        has = true;
    }
    function void() {
        has = false;
    }
}

contract Medianizer is DSValue {
    event DeployOracle(
        address indexed _oracleAddress,
        string _name
    );

    mapping (address => bool)    public tokas;  // Is ERC20 Token Approved
    
    mapping (bytes12 => address) public values;
    mapping (address => bytes12) public indexes;
    bytes12 public next = 0x1;

    uint96 public min = 0x5;
    
    constructor (address _weth) public {
    	BraveNewCoinChainlinkOracle braveNewCoinChainlinkOracle = new BraveNewCoinChainlinkOracle(address(this));
    	set(address(braveNewCoinChainlinkOracle));
    	emit DeployOracle(address(braveNewCoinChainlinkOracle), 'Chainlink_BraveNewCoin')

		CoinbaseOraclizeOracle coinbaseOraclizeOracle = new CoinbaseOraclizeOracle(address(this), _weth);
        set(address(coinbaseOraclizeOracle));
        emit DeployOracle(address(coinbaseOraclizeOracle), "Oraclize_Coinbase");

        CoinGeckoOraclizeOracle coinGeckoOraclizeOracle = new CoinGeckoOraclizeOracle(address(this), _weth);
        set(address(coinGeckoOraclizeOracle));
        emit DeployOracle(address(coinGeckoOraclizeOracle), "Oraclize_CoinGecko");

        CoinMarketCapChainlink coinMarketCapChainlink = new CoinMarketCapChainlink(address(this));
        set(address(coinMarketCapChainlink));
        emit DeployOracle(address(coinMarketCapChainlink), "Chainlink_CoinMarketCap");

        CoinpaprikaOraclizeOracle coinpaprikaOraclizeOracle = new CoinpaprikaOraclizeOracle(address(this), _weth);
        set(address(coinpaprikaOraclizeOracle));
        emit DeployOracle(address(coinpaprikaOraclizeOracle), "Oraclize_Coinpaprika");

        CryptocompareChainlinkOracle cryptocompareChainlinkOracle = new CryptocompareChainlinkOracle(address(this));
        set(address(cryptocompareChainlinkOracle));
        emit DeployOracle(address(cryptocompareChainlinkOracle), "Chainlink_CryptoCompare");

        KaikoChainlinkOracle kaikoChainlinkOracle = new KaikoChainlinkOracle(address(this));
        set(address(kaikoChainlinkOracle));
        emit DeployOracle(address(kaikoChainlinkOracle), "Chainlink_Kaiko");
    }

    function set(address wat) {
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) note {
        if (pos == 0x0) throw;

        if (wat != 0 && indexes[wat] != 0) throw;

        indexes[values[pos]] = 0; // Making sure to remove a possible existing address in that position

        if (wat != 0) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function push (uint256 amt, ERC20 tok) {
    	if (tokas[address(tok)] == false) {
            tokas[address(tok)] = true;
            for (uint96 i = 1; i < uint96(next); i++) {
	    		tok.approve(values[bytes12(i)], 2**256-1);
	    	}
	    	tokas[address(tok)] = true;
        }
    	for (uint96 i = 1; i < uint96(next); i++) {
    		DSValue(values[bytes12(i)]).push(wdiv(uint128(amt), uint128(next)), tok);
    	}
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) note {
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