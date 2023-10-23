// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyComplexToken is ERC20Burnable, Ownable {
    mapping(address => uint256) public lockedBalances;

    event TokensLocked(address indexed holder, uint256 amount, uint256 releaseTime);
    event TokensReleased(address indexed holder, uint256 amount);
    event TokenTransferred(address indexed from, address indexed to, uint256 amount);

    struct LockInfo {
        uint256 releaseTime;
        uint256 amount;
        bool locked;
    }

    mapping(address => LockInfo[]) public lockData;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10**uint256(decimals()));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function lockTokens(address holder, uint256 amount, uint256 releaseTime) public onlyOwner {
        require(holder != address(0), "Invalid address");
        require(releaseTime > block.timestamp, "Release time must be in the future");
        require(balanceOf(holder) >= amount, "Insufficient balance");

        if (lockData[holder].length == 0) {
            transfer(address(this), amount);
        } else {
            require(!lockData[holder][lockData[holder].length - 1].locked, "Previous lock is still active");
        }

        lockedBalances[holder] += amount;
        lockData[holder].push(LockInfo(releaseTime, amount, true));
        emit TokensLocked(holder, amount, releaseTime);
    }

    function releaseLockedTokens() public {
        uint256 totalReleased = 0;
        LockInfo[] storage locks = lockData[msg.sender];

        for (uint256 i = 0; i < locks.length; i++) {
            if (block.timestamp >= locks[i].releaseTime) {
                totalReleased += locks[i].amount;
                locks[i] = locks[locks.length - 1];
                locks.pop();
                i--;
            }
        }

        require(totalReleased > 0, "No tokens to release");
        lockedBalances[msg.sender] -= totalReleased;
        transfer(msg.sender, totalReleased);
        emit TokensReleased(msg.sender, totalReleased);
    }

    function transferTokens(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        require(lockedBalances[msg.sender] >= amount, "Insufficient locked balance");

        lockedBalances[msg.sender] -= amount;
        lockedBalances[to] += amount;
        emit TokenTransferred(msg.sender, to, amount);
    }
}

