// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
   @title Constant Product Automated Market Maker(AMM)
*/
contract CPAMM {
    // token0 & token1 - ERC20 tokens for the Liquidity Pool
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // reserve0 & reserve1 - total balance of each token in the Liquidity Pool
    uint public reserve0;
    uint public reserve1;

    // total shares of the Liquidity Pool
    uint public totalSupply;

    // Mapping of the wallet address and their corresponding Liquidity Pool shares
    mapping(address => uint) public balanceOf;

    /**
    @dev Creates Liquidity Pool with two ERC20 tokens 'token0' & 'token1'
    @param _token0 (ERC20 token) _token1 (ERC20 token)
    */
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /**
    @dev Mints Liquidity Pool shares and updates the balance of the Liquidity Provider's wallet
    @param _to (Liquidity Provider's address) _amount (Number of LP shares to mint)
    */
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    /**
    @dev Burns Liquidity Pool shares and updates the balance of Liquidy Provider's wallet who is removing out his shares
    @param _from (Liquidity Provider's address) _amount (Number of LP shares to burn)
    */
    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
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

        /**
         x*y = K (x = reserve of token0, y = reserve of token1)
         If a dx amount of token0 is being invested in LP for swap, then X will be  X + dx and Y would be Y - dy
         After swap, product of the reserves of token0 & token1 should still be equal to K
         (x+dx)*(y-dy) = K
         x*y = (x+dx)*(y-dy)
         x*y = x*y - x*dy + y*dx - dx*dy
         x*dy + dx*dy = y*dx
         dy = (y*dx)/(x+dx)
         Here dy = amountOut, dx = amountInWithFee, y = reserveOut, x = reserveIn
        
         E.g : If Initial reserve of token0 i.e x = 1000 and reserve of token1 i.e y = 1000,
                For swap, if 50 of token0 is being invested in the pool, what would be amount of token1 that should be returned
                
               x*y = (x+dx)*(y-dy)
               1000*1000 = (1000 + 50)*(1000 - dy)
               1000 - dy = (1000*1000)/(1050)
                      dy = 1000 - 952.38
                      dy = 47.62 i.e For 50 token0 that were invested in the pool, a return of 47.62 token1 are being returned.
        */

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

        /*
        How much dx, dy to add in the Liquidity Pool?
        There shouldn' be any price change before and after adding liquidity.
        Price of a token0 is determined by x/y (reserve of token 0 divided by reserve of token1) and vice versa for token 1
        x / y = (x + dx) / (y + dy)
        x(y + dy) = y(x + dx)
        x * dy = y * dx -> This condition has to be satisfied before proceeding to add liquidity
        x / y = dx / dy
        dy = y / x * dx  
        */
        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "x / y != dx / dy");
        }

        /*
        How much Liquidity Pool shares to mint to return to the Liquidity Provider?
        f(x, y) = value of liquidity
        We will define f(x, y) = sqrt(xy) (Reason being to maintain linearity in the Liquidity)
        L0 = f(x, y)
        L1 = f(x + dx, y + dy)
        T = total number of Liquidity Pool shares
        s = Liquidity Pool shares to mint in exhange of _amount0 and _amount1 of token0 and token1 respectively
        Total shares should increase proportional to increase in liquidity
        
        L1 / L0 = (T + s) / T

        L1 * T = L0 * (T + s)

        (L1 - L0) * T / L0 = s 

        (L1 - L0) / L0 = (sqrt((x + dx)(y + dy)) - sqrt(xy)) / sqrt(xy)
        
        dx / dy = x / y so replace dy = dx * y / x

        (L1 - L0) / L0 = (sqrt(xy + 2ydx + dx^2 * y / x) - sqrt(xy)) / sqrt(xy)

        Multiply by sqrt(x) / sqrt(x)
        (L1 - L0) / L0 = (sqrt(x^2y + 2xydx + dx^2 * y) - sqrt(x^2y)) / sqrt(x^2y)
                       = (sqrt(y)(sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2)) / (sqrt(y)sqrt(x^2))
        
        sqrt(y) on top and bottom cancels out

        (L1 - L0) / L0 = (sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2)) / (sqrt(x^2)
                       = (sqrt((x + dx)^2) - sqrt(x^2)) / sqrt(x^2)  
                       = ((x + dx) - x) / x
                        = dx / x

        Since dx / dy = x / y,
        dx / x = dy / y

        (L1 - L0) / L0 = dx / x = dy / y

        So, L1 - L0 = (dx/x)*L0 = (dy/y)*L0. Here L1-L0 is different in the Liquidity before and after adding which will be
        the number of shares that needs to provided. 
        */

        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
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

        /**
        Amount of Liquidity being removed should be proportional to the Liquity pool shares being provided

        Liquidty being removed, l = sqrt(dx*dy) where dx = amount0 & dy = amount1
        Total Liquidity currently, L = sqrt(x*y) 
 
         l/L = s/T where s = shares in the input, T = total number of shares

         sqrt(dx*dy) = (s/T)*sqrt(x*y). --> eq 1

         There shouldn't be an price impact removing the liquidity

         x/y = (x-dx)/(y-dy)
         
         xy -x*dy = yx - y*dx

         dy = (y/x)*dx 

         replace dy in eq 1

         sqrt(y/x)*dx = (s/T)*sqrt(x*y)

         dx = (s/T)* (sqrt(x*y)/sqrt(y/x))

         dx = (s/T)*x

         Similarly dy = (s/T)*y

         Here s = shares in the input, x & y are bal0 and bal1 respectively, T is the total supply

        */
        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;

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

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}