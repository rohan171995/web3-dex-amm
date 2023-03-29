// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
   @title Constant Product Automated Market Maker(AMM) For CoinDCX
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DCXSwap is ERC20 {
    // token0 & token1 - ERC20 tokens for the Liquidity Pool
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // reserve0 & reserve1 - total balance of each token in the Liquidity Pool
    uint public reserve0;
    uint public reserve1;


    /**
    @dev Creates Liquidity Pool with two ERC20 tokens 'token0' & 'token1'
    @param _token0 (ERC20 token) _token1 (ERC20 token)
    */
    constructor(address _token0, address _token1) ERC20("CoinDCX LP Provider Token", "DCXLP"){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /**
    @dev Updates the balances of the two ERC20 tokens in the Liquidiy Pool
    @param _reserve0 (token0's balance) _reserve1 (token1's balance)
    */
    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /**
    @dev Returns the 'amountOut' of a token which can be provided in trade to '_amountIn' of the second token in the pool.
    @param _tokenIn (address of input token) _amountIn (amount of input token)
    @return amountOut (amount of output token that can be provided if a swap is performed)
    */
    function swapTokenAmount(address _tokenIn, uint _amountIn) external view returns (uint amountOut) {

        // Check which ensures the address of the input token is matching with either of the ERC20 token addresses setup in the Liquidity Pool.
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "invalid token"
        );

        require(_amountIn > 0, "amount in = 0");

        bool isToken0 = _tokenIn == address(token0);
        (uint reserveIn, uint reserveOut) = isToken0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        // Deduct 0.3% as fees from the input amount of tokens. 
        uint amountInWithFee = (_amountIn * 997) / 1000;

        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);
        return amountOut;
    }

    /**
    @dev Returns the 'amountOut' of a token which can be provided in trade to '_amountIn' of the second token in the pool.
    @param _tokenIn (address of input token) _amountIn (amount of input token)
    @return amountOut (amount of output token that can be provided after swap)
    */
    function swap(address _tokenIn, uint _amountIn) external returns (uint amountOut) {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "invalid token"
        );
        require(_amountIn > 0, "amount in = 0");

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) = isToken0
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);

        // Transfer the amount of tokenIn into the contract's address from the sender's wallet
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        uint amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        // Transfer the amount of tokenOut into the sender's wallet from the contract's address
        tokenOut.transfer(msg.sender, amountOut);

        // Update the balances of the respective tokens in the Liquidity Pool
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
    @dev Returns the Liquidity Pool shares for the '_amount0' of token0 and '_amount1' of token1 that were invested in the Liquidity Pool
    @param _amount0 (amount of token0) _amount1 (amount of token1)
    @return shares (Liquidity Pool shares after adding Liquidity to the pool with _amount0 & _amount1)
    */
    function addLiquidity(uint _amount0, uint _amount1) external returns (uint shares) {
        // Transfer the respective tokens invested in the pool from the sender's address to the Liquidity Pool address
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "x / y != dx / dy");
        }

        if (totalSupply() == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                (_amount0 * totalSupply()) / reserve0,
                (_amount1 * totalSupply()) / reserve1
            );
        }

        require(shares > 0, "shares = 0");

        //Mint the Liquidity Pool shares to be assigned to the sender
        _mint(msg.sender, shares);

        //Update the respective token balances in the Liquidity Pool
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
    @dev Returns amount0 of token0 and amount1 of token1 in exchange to the Liquidity Provdier shares
    @param _shares -> Liquidity Pool shares
    */
    function removeLiquidity(uint _shares) external returns (uint amount0, uint amount1) {
        
        // Get the respective token's balances for this contract's address
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply();
        amount1 = (_shares * bal1) / totalSupply();

        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        // Burn the Liquidity provider shares from the sender's wallet
        _burn(msg.sender, _shares);

        // Update the reserves of token0 and token1 respectively
        _update(bal0 - amount0, bal1 - amount1);

        // Transfer these tokens to the sender's wallet
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    /**
    @dev Returns the square root of a number
    */
    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}