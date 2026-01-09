// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface IFlashLoanPoolMock {
    function flashLoan(address receiver, uint256 amount) external;
}

contract MyFlashLoanReceiver {
    address public immutable pool;
    address public immutable asset;

    // Contabilidade de operaçõesv
    uint256 public totalOperations;
    int256 public cumulativePnl;
    int256 public lastNetPnl;

    event FlashLoanStarted(
        address indexed user,      // quem iniciou a tx (tx.origin)
        uint256 amount,
        uint256 premium,
        uint256 balanceBefore
    );

    event ArbitrageSimulated(
        uint256 amountIn,
        uint256 priceDexA,
        uint256 priceDexB,
        int256 pnl               // lucro/prejuízo em "unidades de asset"
    );

    event SwapSimulated(
        uint256 amountIn,
        uint256 priceIn,
        uint256 priceOut,
        int256 pnl
    );

    event LiquidationSimulated(
        address indexed liquidatedUser,
        uint256 debtRepaid,
        uint256 collateralSeized,
        int256 pnl
    );

    event FlashLoanFinished(
        uint256 totalOwed,
        uint256 balanceAfter,
        int256 netPnl
    );

    constructor(address poolAddress, address assetAddress) {
        pool = poolAddress;
        asset = assetAddress;
    }

    function requestFlashLoan(address assetAddress, uint256 amount) external {
        require(assetAddress == asset, "unsupported asset");
        IFlashLoanPoolMock(pool).flashLoan(address(this), amount);
    }

    function executeOperation(uint256 amount, uint256 premium) external returns (bool) {
        require(msg.sender == pool, "caller must be pool");

        uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
        uint256 totalOwed = amount + premium;

        emit FlashLoanStarted(tx.origin, amount, premium, balanceBefore);

        // Arbitragem mock: DEX B 0.3% mais caro que DEX A
        int256 pnlArb = _simulateArbitrage(amount);

        // Swap mock: meio do valor com slippage negativo
        int256 pnlSwap = _simulateSwap(amount / 2);

        // Liquidação mock: liquida metade da posição com bônus de colateral
        int256 pnlLiq = _simulateLiquidation(amount / 2);

        int256 netPnl = pnlArb + pnlSwap + pnlLiq;
        lastNetPnl = netPnl;
        cumulativePnl += netPnl;
        totalOperations += 1;

        uint256 balanceAfter = IERC20(asset).balanceOf(address(this));
        require(balanceAfter >= totalOwed, "not enough balance to repay");

        // Aave-style: aprova o pool para puxar o valor devido via transferFrom
        require(IERC20(asset).approve(pool, totalOwed), "approve failed");

        emit FlashLoanFinished(totalOwed, balanceAfter, netPnl);

        return true;
    }

    // Arbitragem simples: assume DEX B 0.3% mais caro e 0.05% de taxa total
    function _simulateArbitrage(uint256 amount) internal returns (int256 pnl) {
        // lucro bruto 0.3%
        uint256 gross = (amount * 3) / 1000; 
        // taxas 0.05%
        uint256 fees = (amount * 5) / 10000; 
        int256 net = int256(gross) - int256(fees);

        emit ArbitrageSimulated(
            amount,
            1000,   // preço fictício DEX A
            1003,   // preço fictício DEX B
            net
        );

        return net;
    }

    // Swap mock: simula slippage negativo de 0.1%
    function _simulateSwap(uint256 amount) internal returns (int256 pnl) {
        uint256 loss = (amount * 1) / 1000; // 0.1%
        int256 net = -int256(loss);

        emit SwapSimulated(
            amount,
            1000, // preço teórico
            999,  // preço efetivo com slippage
            net
        );

        return net;
    }

    // Liquidação mock: repaga dívida e recebe 8% a mais em colateral
    function _simulateLiquidation(uint256 amount) internal returns (int256 pnl) {
        uint256 collateral = (amount * 108) / 100;
        int256 net = int256(collateral) - int256(amount);

        emit LiquidationSimulated(
            tx.origin,  // "devedor" fictício
            amount,
            collateral,
            net
        );

        return net;
    }
}