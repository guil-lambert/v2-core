pragma solidity =0.5.16;

import "./ERC20.sol";
import "../UniswapV2Pair.sol";
import "../libraries/UniswapV2Library.sol";

contract UniswapV2PairTest {

    using SafeMath for uint256;
    using Math for uint256;

    UniswapV2Pair pair;
    ERC20 dai;
    ERC20 cnv;

    // baseline to measure against
    function getAmountOutWithoutFee(
        uint256 amountIn, 
        uint256 reserveIn, 
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn;
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setUp() public {
        // setup test contracts
        dai  = new ERC20(1010e18);
        cnv  = new ERC20(1000e18);
        pair = new UniswapV2Pair();
        
        // initialize & transfer initial liquidity to pair
        pair.initialize(address(dai), address(cnv));
        dai.transfer(address(pair), 1000e18);
        cnv.transfer(address(pair), 1000e18);

        // mint initial liquidity tokens to this contract
        pair.mint(address(this));
    }

    function test_getAmountOut() public {
        // calculate amountOut
        uint256 amountOut = UniswapV2Library.getAmountOut(1e18, 1000e18, 1000e18, 0);

        // transfer swap input to pair
        dai.transfer(address(pair), 1e18);

        // swap 1 dai for amountOut of cnv, fails if you add 1 wei
        pair.swap(0, amountOut, address(this), new bytes(0));
    }

    // I found this test odd, should there ever be a case where a fee is not charged?
    function test_getAmountOut_fee() public {
        // calculate adjusted amountOut
        uint256 amountOutAdjusted = UniswapV2Library.getAmountOut(1e18, 1000e18, 1000e18, 0);

        // calculate amountOut without fee to provide a baseline
        uint256 amountOutNoFee = getAmountOutWithoutFee(1e18, 1000e18, 1000e18);

        // This test passes, should it?
        require(amountOutAdjusted == amountOutNoFee, toString(amountOutAdjusted.sub(amountOutNoFee)));
    }

    function test_getAmountIn() public {
        // calculate amountIn
        uint256 amountIn = UniswapV2Library.getAmountIn(1e18, 1000e18, 1000e18, 0);
        
        // transfer calculated swap input to pair
        dai.transfer(address(pair), amountIn);
        
        // swap amoutnIn of dai for 1 cnv, fails if you add 1 wei
        pair.swap(0, 1e18, address(this), new bytes(0));
    }
}
