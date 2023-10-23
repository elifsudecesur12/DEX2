// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ComplexAMM is Ownable {
    IERC20 public token1;
    IERC20 public token2;
    uint256 public totalSupply;
    uint256 public feePercentage;
    uint256 public slippageTolerance;

    event Swap(address indexed user, uint256 inputAmount, uint256 outputAmount);
    event AddLiquidity(address indexed user, uint256 amount1, uint256 amount2, uint256 liquidity);
    event RemoveLiquidity(address indexed user, uint256 liquidity, uint256 amount1, uint256 amount2);

    constructor(address _token1, address _token2, uint256 _feePercentage, uint256 _slippageTolerance) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        feePercentage = _feePercentage;
        slippageTolerance = _slippageTolerance;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        feePercentage = _feePercentage;
    }

    function swapTokens(uint256 amountIn, uint256 amountOutMin) external {
        require(amountIn > 0, "AmountIn must be greater than 0");

        uint256 amountOut = calculateSwapOutput(amountIn);
        require(amountOut >= amountOutMin, "Slippage too high");

        uint256 fee = (amountIn * feePercentage) / 100;
        uint256 amountInAfterFee = amountIn - fee;

        require(token1.transferFrom(msg.sender, address(this), amountInAfterFee), "Transfer of token1 failed");
        require(token2.transfer(msg.sender, amountOut), "Transfer of token2 failed");

        emit Swap(msg.sender, amountInAfterFee, amountOut);
    }

    function addLiquidity(uint256 amount1, uint256 amount2) external {
        require(amount1 > 0 && amount2 > 0, "Amounts must be greater than 0");

        require(token1.transferFrom(msg.sender, address(this), amount1), "Transfer of token1 failed");
        require(token2.transferFrom(msg.sender, address(this), amount2), "Transfer of token2 failed");

        uint256 liquidity = calculateLiquidity(amount1, amount2);
        totalSupply += liquidity;

        emit AddLiquidity(msg.sender, amount1, amount2, liquidity);
    }

    function removeLiquidity(uint256 liquidity, uint256 amount1Min, uint256 amount2Min) external {
        require(liquidity > 0, "Liquidity must be greater than 0");

        uint256 amount1 = (liquidity * token1.balanceOf(address(this))) / totalSupply;
        uint256 amount2 = (liquidity * token2.balanceOf(address(this))) / totalSupply;

        require(amount1 >= amount1Min, "Slippage too high for token1");
        require(amount2 >= amount2Min, "Slippage too high for token2");

        require(token1.transfer(msg.sender, amount1), "Transfer of token1 failed");
        require(token2.transfer(msg.sender, amount2), "Transfer of token2 failed");

        totalSupply -= liquidity;

        emit RemoveLiquidity(msg.sender, liquidity, amount1, amount2);
    }

    function calculateSwapOutput(uint256 amountIn) internal view returns (uint256) {
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 balance2 = token2.balanceOf(address(this));
        return (balance2 * amountIn) / balance1;
    }

    function calculateLiquidity(uint256 amount1, uint256 amount2) internal view returns (uint256) {
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 balance2 = token2.balanceOf(address(this));
        return (totalSupply == 0) ? (amount1 * amount2) : (amount1 * totalSupply) / balance1;
    }
}
