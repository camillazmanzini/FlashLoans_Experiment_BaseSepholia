// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface IFlashLoanReceiver {
    function executeOperation(uint256 amount, uint256 premium) external returns (bool);
}

contract FlashLoanPoolMock {
    IERC20 public asset;
    uint256 public premiumRate = 5;

    event LiquidityDeposited(address indexed provider, uint256 amount);
    event FlashLoanRequested(
        address indexed caller,
        address indexed receiver,
        uint256 amount,
        uint256 premium
    );
    event FlashLoanRepaid(
        address indexed receiver,
        uint256 amount,
        uint256 premium,
        uint256 newPoolBalance
    );

    constructor(address assetAddress) {
        asset = IERC20(assetAddress);
    }

    function depositLiquidity(uint256 amount) external {
        require(asset.transferFrom(msg.sender, address(this), amount), "deposit failed");
        emit LiquidityDeposited(msg.sender, amount);
    }

    function flashLoan(address receiver, uint256 amount) external {
        uint256 balanceBefore = asset.balanceOf(address(this));
        require(balanceBefore >= amount, "not enough liquidity");

        uint256 premium = (amount * premiumRate) / 10000;

        emit FlashLoanRequested(msg.sender, receiver, amount, premium);

        require(asset.transfer(receiver, amount), "transfer failed");

        require(
            IFlashLoanReceiver(receiver).executeOperation(amount, premium),
            "callback failed"
        );

        require(
            asset.transferFrom(receiver, address(this), amount + premium),
            "repay failed"
        );

        uint256 balanceAfter = asset.balanceOf(address(this));
        emit FlashLoanRepaid(receiver, amount, premium, balanceAfter);

        require(balanceAfter >= balanceBefore + premium, "pool didn't receive premium");
    }

    function poolBalance() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }
}