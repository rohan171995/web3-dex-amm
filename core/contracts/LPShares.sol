// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

contract LPShares is ERC20 {

    struct Incentives { 
        mapping(string => uint256) balances;
        mapping(address => uint256) rewards;
    }

    address [] private lpShareAddresses;
    mapping(address => Incentives) private incentives;
    uint256 private _totalSupply;
    address public owner;
    address public swapContract;

    constructor(uint256 initialSupply) ERC20("LPShares", "LPSRS") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "operation not allowed");
        _;
    }

    modifier authorisedContract {
        require(msg.sender == swapContract, "operation not allowed");
        _;
    }

    function allowSwap(address _swapContract) public onlyOwner {
        swapContract = _swapContract;
    }

    function _transfer(address from, address to, uint256 amount) internal override virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (incentives[to].balances == 0) {
            lpShareAddresses.push(to);
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = incentives[from].balances;
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            incentives[from].balances = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            incentives[to].balances += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);

    }

    function mint(address _token1, address token2, address account, uint256 amount) public authorisedContract {

        if (incentives[account].balances == 0) {
            lpShareAddresses.push(account);
        }
        _mint(account, amount);
    }  

    function burn(address account, uint256 amount) public authorisedContract {

        _burn(account, amount);
    }

    function incentiviseUser(address token1, address token2, address token, uint256 amount) public authorisedContract {
        for (int i=0; i< lpShareAddresses.length; i++) {
            uint256 totalRewards = mul(div(mul(div(incentives[lpShareAddresses[i]].balances, _totalSupply), 100), 100), amount);
            incentives[lpShareAddresses[i]].rewards[token] += totalRewards;
        }
    }

    function claimIncentive(address user, address _token) public authorisedContract {
        uint256 totalRewards = incentives[user].rewards[_token];
        require(totalRewards > 0, "no rewards available for this token");
        IERC20 token = IERC20(_token);
        incentives[user].rewards[_token] -= totalRewards;
        token.transfer(user, totalRewards);
    }
}