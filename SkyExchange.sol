// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract SkyExchange {

    event Sell(address indexed seller, uint256 amount, uint256 price);
    event RemoveSale(uint256 indexed saleId);
    event Buy(uint256 indexed saleId, address indexed buyer, uint256 amount);
    event CancelSale(uint256 indexed saleId);

    ERC20 token;

    struct Sale {
        address seller;
        uint256 amount;
        uint256 soldAmount;
        uint256 price;
    }
    Sale[] public sales;

    constructor(address tokenAddress) {
        token = ERC20(tokenAddress);
    }

    function saleCount() external view returns (uint256) {
        return sales.length;
    }

    function sell(uint256 amount, uint256 price) external {
        token.transferFrom(msg.sender, address(this), amount);
        sales.push(Sale({
            seller: msg.sender,
            amount: amount,
            soldAmount: 0,
            price: price
        }));
        emit Sell(msg.sender, amount, price);
    }

    function removeSale(uint256 saleId) internal {
        delete sales[saleId];
        emit RemoveSale(saleId);
    }

    function buy(uint256 saleId) payable external {
        Sale storage sale = sales[saleId];
        uint256 _saleAmount = sale.amount;
        uint256 _soldAmount = sale.soldAmount;

        uint256 amount = _saleAmount * msg.value / sale.price;
        require(amount <= _saleAmount - _soldAmount);
        token.transfer(msg.sender, amount);
        _soldAmount += amount;
        if (_saleAmount == _soldAmount) {
            removeSale(saleId);
        }
        sale.soldAmount = _soldAmount;

        emit Buy(saleId, msg.sender, amount);
    }

    function cancelSale(uint256 saleId) external {
        Sale memory sale = sales[saleId];
        require(sale.seller == msg.sender);
        token.transfer(msg.sender, sale.amount - sale.soldAmount);
        removeSale(saleId);
        emit CancelSale(saleId);
    }
}
