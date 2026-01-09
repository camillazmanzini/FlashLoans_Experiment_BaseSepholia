# Flash Loan Mock - Experimento Base Sepolia

## Visão Geral

O Flash Loan Mock Base Sepolia é um ambiente completo de simulação
inspirado no comportamento do protocolo Aave V3, desenvolvido
utilizando Solidity + Hardhat + Node.js (scripts) e executado
diretamente na rede Base Sepolia Testnet.

Este experimento foi criado com o objetivo de:

-   Simular de forma realista um fluxo de Flash Loan;
-   Implementar um Pool com liquidez e cobrança de premium;
-   Implementar um Receiver capaz de executar estratégias
    arbitrárias no callback;
-   Criar scripts automatizados para wrap (ETH→WETH), supply, funding e
    execução de flash loans;
-   Permitir evolução futura para estratégias reais (AMM, arbitragem
    multi-hop, liquidações reais etc.).

O experimento resultou em um ambiente completamente funcional, com logs
detalhados e operações comprovadamente executadas on-chain.

## Estrutura do Projeto

    aave-flash-loans-experiment-base/
    ├── contracts/
    │   ├── FlashLoanPoolMock.sol
    │   └── MyFlashLoanReceiver.sol
    │
    ├── scripts/
    │   ├── wrap.js
    │   ├── deposit.js
    │   ├── fund_receiver.js
    │   ├── flashloan.js
    │   ├── deploy_pool.js
    │   └── deploy_receiver.js
    │
    ├── abi/
    │   └── IERC20.json
    │
    ├── .env
    ├── hardhat.config.js
    └── README.md

## Arquitetura do Sistema

  --------------------------------------------------------------------------------
  Camada           Responsabilidade                    Arquivos
  ---------------- ----------------------------------- ---------------------------
  **Smart          Implementam o Pool e o Receiver     `FlashLoanPoolMock.sol`,
  Contracts**      customizado                         `MyFlashLoanReceiver.sol`

  **Scripts de     Executam wrap, deposit, funding e   `scripts/*.js`
  Orquestração**   flash loans                         

  **ABI Local**    Interface ERC20 para WETH           `abi/IERC20.json`

  **Ambiente       Compilação, deploy e execução       `hardhat.config.js`
  Hardhat**                                            
  --------------------------------------------------------------------------------

## Contratos Principais

### FlashLoanPoolMock.sol

Implementa:

-   Depósito de liquidez (WETH);
-   Empréstimo instantâneo (flash loan);
-   Cálculo automático de premium (`premiumRate = 5` → 0.05%);
-   Eventos detalhados:
    -   `LiquidityDeposited`
    -   `FlashLoanRequested`
    -   `FlashLoanRepaid`

Requer `transferFrom` para repagamento.

------------------------------------------------------------------------

### MyFlashLoanReceiver.sol

Implementa:

-   Callback `executeOperation()`;
-   Três estratégias simuladas:
    -   Arbitragem (+0.3% bruto -- taxas)
    -   Swap com slippage (-0.1%)
    -   Liquidação com bônus de colateral (8%)
-   Registros de PnL:
    -   `cumulativePnl`
    -   `lastNetPnl`
    -   `totalOperations`
-   Eventos detalhados:
    -   `FlashLoanStarted`
    -   `ArbitrageSimulated`
    -   `SwapSimulated`
    -   `LiquidationSimulated`
    -   `FlashLoanFinished`

------------------------------------------------------------------------

## Fluxo Completo do Experimento

### Wrap ETH → WETH

O contrato WETH nativo da Base Sepolia recebe ETH no próprio endereço do
token:

``` js
await signer.sendTransaction({ to: WETH, value: amount })
```

Saldo final obtido:

    0.024 WETH

------------------------------------------------------------------------

### Depositar Liquidez no Pool (0.015 WETH)

    ✔️ Approve ok
    ✔️ Liquidez depositada com sucesso

Pool Final:

    0.015 WETH

------------------------------------------------------------------------

### Executar Flash Loan (0.005 WETH)

Transação enviada:

    0x3744c8970f97f4c7257a86367d2d5b29cab1e31ee3df50675e76f02a036241ba

Bloco:

    34507268

### Eventos Gerados (Resumo)

#### **Pool: FlashLoanRequested**

    amount: 0.005 WETH
    premium: 0.0000025 WETH

#### **Receiver: FlashLoanStarted**

    balanceBefore: 0.006 WETH

#### **ArbitrageSimulated**

    pnl = +0.0000125 WETH

#### **SwapSimulated**

    pnl = -0.0000025 WETH

#### **LiquidationSimulated**

    pnl = +0.00020 WETH

#### PnL Final

    netPnl = +0.00021 WETH

#### Repagamento

    totalOwed = 0.0050025 WETH
    poolBalanceFinal = 0.0150025 WETH

------------------------------------------------------------------------

## Resultado Final do Experimento

  -----------------------------------------------------------------------
  Etapa              Status                  Evidência
  ------------------ ----------------------- ----------------------------
  **Wrap             ✅ Sucesso              WETH gerado on-chain
  (ETH→WETH)**                               

  **Deposit          ✅ Sucesso              Pool recebeu 0.015 WETH
  (Liquidity)**                              

  **Flash Loan**     ✅ Sucesso              Eventos completos executados

  **PnL              🔥 Positivo (+0.00021   Logs detalhados
  (estratégias)**    WETH)                   

  **Receiver**       ✔ Funcionou             Repagamento + lucro
                     perfeitamente           

  **Pool**           ✔ Recebeu premium       Saldo final consistente
  -----------------------------------------------------------------------

## Conclusão

O experimento resultou em um ambiente completamente funcional de
simulação de Flash Loans, com:

-   **eventos detalhados;**
-   **PnL real no receiver;**
-   **lógica de arbitragem / swap / liquidação simulada;**
-   **premium cobrado e repagamento correto;**
-   **operações comprovadas on-chain na Base Sepolia.**

Este projeto agora serve como base sólida para:

-   AMMs simuladas (Uniswap V2);
-   arbitragem multi-hop;
-   liquidações reais;
-   dashboards de PnL;
-   loops automáticos para múltiplos flash loans.

**Autor:** Camilla Manzini\
**Data da validação:** Dezembro / 2025\
**Rede:** Base Sepolia\
**Tecnologias:** Solidity · Hardhat · WETH · Node.js
