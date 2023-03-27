// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract LPShares is ERC20 {

    struct Incentives { 
        mapping(string => uint256) balances;
        mapping(address => uint256) rewards;
    }

    mapping(string => address []) private lpShareAddresses;
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
        require(false, "transfer not allowed");
        // require(from != address(0), "ERC20: transfer from the zero address");
        // require(to != address(0), "ERC20: transfer to the zero address");

        // _beforeTokenTransfer(from, to, amount);

        // uint256 fromBalance = incentives[from].balances;
        // require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        // unchecked {
        //     incentives[from].balances = fromBalance - amount;
        //     // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        //     // decrementing then incrementing.
        //     incentives[to].balances += amount;
        // }

        // emit Transfer(from, to, amount);

        // _afterTokenTransfer(from, to, amount);

    }

    function mint(address token1, address token2, address account, uint256 amount) public authorisedContract {
        string memory _token1 = toString(token1);
        string memory _token2 = toString(token2);

        if(incentives[account].balances[string.concat(_token1, _token2)] > 0) {
            incentives[account].balances[string.concat(_token1, _token2)] += amount;
        } else if(incentives[account].balances[string.concat(_token2, _token1)] > 0) {
            incentives[account].balances[string.concat(_token2, _token1)] += amount;
        } else{
            lpShareAddresses[string.concat(_token1, _token2)].push(account);
            incentives[account].balances[string.concat(_token1, _token2)] = amount;
        }
        _mint(account, amount);
    }  

    function burn(address token1, address token2, address account, uint256 amount) public authorisedContract {
        string memory _token1 = toString(token1);
        string memory _token2 = toString(token2);

        if(incentives[account].balances[string.concat(_token1, _token2)] > 0) {
            incentives[account].balances[string.concat(_token1, _token2)] -= amount;
        } else if(incentives[account].balances[string.concat(_token2, _token1)] > 0) {
            incentives[account].balances[string.concat(_token2, _token1)] -= amount;
        } else{
            require(false, "can't perform burn operation");
        }
        _burn(account, amount);
    }

    function incentiviseLPProviders(address token1, address token2, address token, uint256 amount) public authorisedContract {
        string memory lpId;
        string memory _token1 = toString(token1);
        string memory _token2 = toString(token2);
        if(lpShareAddresses[string.concat(_token1, _token2)].length > 0) {
            lpId = string.concat(_token1, _token2);
        } else if(lpShareAddresses[string.concat(_token2, _token1)].length > 0) {
            lpId = string.concat(_token2, _token1);
        }
        for (uint i=0; i < lpShareAddresses[lpId].length; i++) {
            if(incentives[lpShareAddresses[lpId][i]].balances[lpId] > 0) {
                console.log("LP Incentive for id: ", lpId, "is: " ,incentives[lpShareAddresses[lpId][i]].balances[lpId]);
                console.log("Rewards for id: ", lpId, "is: " ,incentives[lpShareAddresses[lpId][i]].rewards[token]);
                // uint256 totalRewards = ((((incentives[lpShareAddresses[lpId][i]].balances[lpId] / _totalSupply) * 100) / 100) * amount);
                // incentives[lpShareAddresses[lpId][i]].rewards[token] += totalRewards;
            }
        }
    }

    function claimIncentive(address user, address _token) public authorisedContract {
        uint256 totalRewards = incentives[user].rewards[_token];
        require(totalRewards > 0, "no rewards available for this token");
        IERC20 token = IERC20(_token);
        incentives[user].rewards[_token] -= totalRewards;
        token.transfer(user, totalRewards);
    }

    function toString(address account) public pure returns(string memory) {
        uint160 i = uint160(account);
        return Strings.toHexString(i, 20);
    }
}