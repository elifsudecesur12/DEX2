// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyComplexTradeContract is Ownable {
    IERC20 public token1;
    IERC20 public token2;

    enum TradeStatus { Created, Executed, Cancelled }
    
    struct Trade {
        address sender;
        uint256 amountIn;
        uint256 amountOut;
        TradeStatus status;
    }
    
    mapping(uint256 => Trade) public trades;
    uint256 public tradeCounter;
    
    event TradeCreated(uint256 tradeId, address sender, uint256 amountIn, uint256 amountOut);
    event TradeExecuted(uint256 tradeId, address sender, uint256 amountIn, uint256 amountOut);
    event TradeCancelled(uint256 tradeId, address sender, uint256 amountIn, uint256 amountOut);
    
    constructor(address _token1, address _token2) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function createTrade(uint256 amountIn, uint256 amountOut) external {
        require(amountIn > 0, "AmountIn must be greater than 0");
        require(amountOut > 0, "AmountOut must be greater than 0");
        
        tradeCounter++;
        trades[tradeCounter] = Trade(msg.sender, amountIn, amountOut, TradeStatus.Created);
        emit TradeCreated(tradeCounter, msg.sender, amountIn, amountOut);
    }

    function executeTrade(uint256 tradeId) external onlyOwner {
        Trade storage trade = trades[tradeId];
        require(trade.status == TradeStatus.Created, "Trade is not in Created state");
        
        require(token1.transferFrom(trade.sender, address(this), trade.amountIn), "Transfer of token1 failed");
        require(token2.transfer(trade.sender, trade.amountOut), "Transfer of token2 failed");
        
        trade.status = TradeStatus.Executed;
        emit TradeExecuted(tradeId, trade.sender, trade.amountIn, trade.amountOut);
    }

    function cancelTrade(uint256 tradeId) external onlyOwner {
        Trade storage trade = trades[tradeId];
        require(trade.status == TradeStatus.Created, "Trade is not in Created state");
        
        trade.status = TradeStatus.Cancelled;
        emit TradeCancelled(tradeId, trade.sender, trade.amountIn, trade.amountOut);
    }
}
