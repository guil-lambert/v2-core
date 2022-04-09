pragma solidity =0.5.16;

import "./ERC20.sol";
import "../UniswapV2Pair.sol";
import "../UniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";
import "../test/test.sol";
import "../test/VM.sol";

contract UniswapV2PairTest is DSTest {

    using SafeMath for uint256;
    using Math for uint256;

    /* -------------------------------------------------------------------------- */
    /*                               MOCK CONTRACTS                               */
    /* -------------------------------------------------------------------------- */

    UniswapV2Factory factory;
    UniswapV2Pair pair;
    ERC20 dai;
    ERC20 cnv;

    VM vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /* -------------------------------------------------------------------------- */
    /*                                 TEST SETUP                                 */
    /* -------------------------------------------------------------------------- */

    function setUp() public {
        // setup test contracts
        dai     = new ERC20(1010e18);
        cnv     = new ERC20(1000e18);
        factory = new UniswapV2Factory(address(this));

        pair    = UniswapV2Pair(factory.createPair(address(dai), address(cnv)));
        
        // transfer initial liquidity to pair
        dai.transfer(address(pair), 1000e18);
        cnv.transfer(address(pair), 1000e18);

        // mint initial liquidity tokens to this contract
        pair.mint(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                               HELPER METHODS                               */
    /* -------------------------------------------------------------------------- */

    // calculates baseline amountOut to measure against
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

    /* -------------------------------------------------------------------------- */
    /*                                 UNIT TESTS                                 */
    /* -------------------------------------------------------------------------- */

    function test_getAmountOut() public {
        // calculate amountOut
        uint256 amountOut = UniswapV2Library.getAmountOut(1e18, 1000e18, 1000e18, 0);

        // transfer swap input to pair
        dai.transfer(address(pair), 1e18);

        // swap 1 dai for amountOut of cnv, should not fail
        pair.swap(amountOut, 0, address(this), new bytes(0));
    }

    function test_getAmountOut_expect_failure() public {
        // calculate amountOut
        uint256 amountOut = UniswapV2Library.getAmountOut(1e18, 1000e18, 1000e18, 0);

        // transfer swap input to pair
        dai.transfer(address(pair), 1e18);

        // swap 1 dai for amountOut plus 1 wei of cnv, should fail on invariant check
        vm.expectRevert("UniswapV2: K");
        pair.swap(amountOut + 1, 0, address(this), new bytes(0));
    }

    // I found this test odd, should there ever be a case where a fee is not charged?
    function test_getAmountOut_fee() public {
        // calculate adjusted amountOut
        uint256 amountOutAdjusted = UniswapV2Library.getAmountOut(1e18, 1000e18, 1000e18, 15);

        // calculate amountOut without fee to provide a baseline
        uint256 amountOutNoFee = getAmountOutWithoutFee(1e18, 1000e18, 1000e18);

        uint256 amountDelta = amountOutNoFee.sub(amountOutAdjusted);

        // log difference
        emit log(toString(amountDelta));

        // make sure adjusted amount is less than baseline
        require(amountOutAdjusted < amountOutNoFee, "adjustedAmount should be greater than baseline");
    }

    function test_getAmountIn() public {
        // calculate amountIn
        uint256 amountIn = UniswapV2Library.getAmountIn(1e18, 1000e18, 1000e18, 0);
        
        // transfer calculated swap input to pair
        dai.transfer(address(pair), amountIn);
        
        // swap amoutnIn of dai for 1 cnv, should not fail
        pair.swap(1e18, 0, address(this), new bytes(0));
    }

    function test_getAmountIn_expect_failure() public {
        // calculate amountIn
        uint256 amountIn = UniswapV2Library.getAmountIn(1e18, 1000e18, 1000e18, 0);
        
        // transfer calculated swap input to pair
        dai.transfer(address(pair), amountIn);
        
        // swap amoutnIn of dai for 1 cnv plus 1 wei, should fail on invariant check
        vm.expectRevert("UniswapV2: K");
        pair.swap(1e18 + 1, 0, address(this), new bytes(0));
    }
}
