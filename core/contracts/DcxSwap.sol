// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LPShares.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DcxSwap is Ownable{

    struct LiquidityPool { 
        address token1;
        address token2;
        uint token1Quantity;
        uint token2Quantity;
    }

    LPShares public lpShares;
    mapping(address => mapping(string => LiquidityPool)) public liquidityPool;

    constructor(address _lpShares) {
        lpShares = LPShares(_lpShares);
    }

    function _mint(address _token1, address token2, address _to, uint _amount) private {
        lpShares.mint(_token1, _token2, _to, _amount);
    }

    function _burn(address _token1, address token2, address _from, uint _amount) private {
        lpShares.burn(_token1, _token2, _from, _amount);
    }

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn) external {
        require(_amountIn > 0, "amount in = 0");
        require(IERC20(_tokenIn).allowance(msg.sender, this) >= _amountIn, "insufficient allowance to smart contract");

        uint amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        require(IERC20(_tokenOut).balanceOf(this) >= amountOut, "out of liquidity");

        tokenIn.transferFrom(msg.sender, address(this), amountInWithFee);
        tokenOut.transfer(msg.sender, amountOut);

        tokenIn.transfer(address(lpShares), (_amountIn - amountInWithFee));
        lpShares.incentiviseUser(_tokenIn, _tokenOut,  _tokenIn, (_amountIn - amountInWithFee));

    }

    function addLiquidity(address _token1, address _token2, uint _amount1, uint _amount2) external returns (uint shares) {

        require(_amount1 > 0, "amount 1 = 0");
        require(_amount2 > 0, "amount 2 = 0");

        require(IERC20(_token1).allowance(msg.sender, this) >= _amountIn, "insufficient allowance of token 1 to smart contract");
        require(IERC20(_token2).allowance(msg.sender, this) >= _amountIn, "insufficient allowance of token 2 to smart contract");

        _token1.transferFrom(msg.sender, address(this), _amount1);
        _token2.transferFrom(msg.sender, address(this), _amount2);

        /*
        How much dx, dy to add?

        xy = k
        (x + dx)(y + dy) = k'

        No price change, before and after adding liquidity
        x / y = (x + dx) / (y + dy)

        x(y + dy) = y(x + dx)
        x * dy = y * dx

        x / y = dx / dy
        dy = y / x * dx
        */
        if (IERC20(_token1).balanceOf(this) > 0 || IERC20(_token2).balanceOf(this) > 0) {
            require(IERC20(_token1).balanceOf(this) * _amount2 == IERC20(_token2).balanceOf(this) * _amount1, "x / y != dx / dy");
        }

        /*
        How much shares to mint?

        f(x, y) = value of liquidity
        We will define f(x, y) = sqrt(xy)

        L0 = f(x, y)
        L1 = f(x + dx, y + dy)
        T = total shares
        s = shares to mint

        Total shares should increase proportional to increase in liquidity
        L1 / L0 = (T + s) / T

        L1 * T = L0 * (T + s)

        (L1 - L0) * T / L0 = s 
        */

        /*
        Claim
        (L1 - L0) / L0 = dx / x = dy / y

        Proof
        --- Equation 1 ---
        (L1 - L0) / L0 = (sqrt((x + dx)(y + dy)) - sqrt(xy)) / sqrt(xy)
        
        dx / dy = x / y so replace dy = dx * y / x

        --- Equation 2 ---
        Equation 1 = (sqrt(xy + 2ydx + dx^2 * y / x) - sqrt(xy)) / sqrt(xy)

        Multiply by sqrt(x) / sqrt(x)
        Equation 2 = (sqrt(x^2y + 2xydx + dx^2 * y) - sqrt(x^2y)) / sqrt(x^2y)
                   = (sqrt(y)(sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2)) / (sqrt(y)sqrt(x^2))
        
        sqrt(y) on top and bottom cancels out

        --- Equation 3 ---
        Equation 2 = (sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2)) / (sqrt(x^2)
        = (sqrt((x + dx)^2) - sqrt(x^2)) / sqrt(x^2)  
        = ((x + dx) - x) / x
        = dx / x

        Since dx / dy = x / y,
        dx / x = dy / y

        Finally
        (L1 - L0) / L0 = dx / x = dy / y
        */
        uint256 totalSuppy = IERC20(_token1).balanceOf(this) * IERC20(_token2).balanceOf(this);

        if (totalSupply == 0) {
            shares = _sqrt(_amount1 * _amount2);
        } else {
            shares = _min(
                (_amount1 * totalSupply) / IERC20(_token1).balanceOf(this),
                (_amount2 * totalSupply) / IERC20(_token2).balanceOf(this)
            );
        }
        require(shares > 0, "shares = 0");
        _mint(_token1, _token2, msg.sender, shares);

    }

    function removeLiquidity(address _token1, address _token2,
        uint _shares
    ) external returns (uint amount0, uint amount1) {
        /*
        Claim
        dx, dy = amount of liquidity to remove
        dx = s / T * x
        dy = s / T * y

        Proof
        Let's find dx, dy such that
        v / L = s / T
        
        where
        v = f(dx, dy) = sqrt(dxdy)
        L = total liquidity = sqrt(xy)
        s = shares
        T = total supply

        --- Equation 1 ---
        v = s / T * L
        sqrt(dxdy) = s / T * sqrt(xy)

        Amount of liquidity to remove must not change price so 
        dx / dy = x / y

        replace dy = dx * y / x
        sqrt(dxdy) = sqrt(dx * dx * y / x) = dx * sqrt(y / x)

        Divide both sides of Equation 1 with sqrt(y / x)
        dx = s / T * sqrt(xy) / sqrt(y / x)
           = s / T * sqrt(x^2) = s / T * x

        Likewise
        dy = s / T * y
        */

        // bal0 >= reserve0
        // bal1 >= reserve1
        uint bal0 = token1.balanceOf(address(this));
        uint bal1 = token2.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        _burn(_token1, _token2, msg.sender, _shares);

        token1.transfer(msg.sender, amount0);
        token2.transfer(msg.sender, amount1);
    }

    function claimIncentive(address user, address _token) public {
        lpShares.claimIncentive(user, _token);
    }

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