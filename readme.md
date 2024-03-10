# FX-Linked Decentralized Stable Coin (FxDSC) Engine

![Solidity Version](https://img.shields.io/badge/Solidity-0.8.18-blue?logo=solidity)
![First Stablecoin Pegged](https://img.shields.io/badge/Pegged-USDffx%20%241.00-green)
![Collateral Supported](https://img.shields.io/badge/Collateral-wETH%20|%20wBTC-orange)
![Stability Mechanism](https://img.shields.io/badge/Stability-Multiple--Algo--Decentralized-purple)

The **FX-Linked Decentralized Stable Coin Engine** is designed to power a series of autonomous, decentralized, algorithmic stablecoins, each pegged to different fiat currencies. Our first product, **USDffx**, is pegged 1:1 with the USD, offering a robust, governance-free, and stable digital currency. Backed by wETH and wBTC, it's just the beginning of our journey towards creating a comprehensive suite of FX-linked stablecoins.

## Key Features
- **Chainlink PriceFeed**: Leverages accurate, up-to-date, and tamper-resistant price data for each stablecoin.
- **Modular Stability Mechanisms**: Each FX-linked stablecoin, starting with USDffx, is stabilized algorithmically through decentralized mechanisms tailored to its specific market.
- **Overcollateralized**: Maintains collateral value greater than the dollar value of each stablecoin, ensuring robustness and trust.
- **Multiple Collaterals**: Initial backing through wETH and wBTC, with plans to expand collateral options as we grow.

## Engine Overview
The [FxDSCengine.sol](./contracts/FxDSCengine.sol) contract series will serve as the core for each stablecoin. The first engine, dedicated to USDffx, will handle:
- Collateral deposits and withdrawals.
- Minting and redeeming of USDffx.
- Position health checks and liquidation.

## Functions (USDffx Engine Example)

1. `depositCollateralAndMintUsdffx()`: Deposit collateral and mint USDffx in one transaction.
2. `depositCollateral()`: Deposit collateral without minting.
3. `redeemCollateralForUsdffx()`: Redeem USDffx for its collateral value.
4. `redeemCollateral()`: Withdraw collateral.
5. `mintUsdffx()`: Mint new USDffx tokens.
6. `burnUsdffx()`: Burn USDffx tokens.
7. `liquidate()`: Liquidate positions not meeting the health factor.
8. `getHealthFactor()`: Check the health factor of a position.

## Future Vision

In the future, we will introduce multiple engines for different FX-linked stablecoins, each with its own unique features and stabilization mechanisms, broadening our ecosystem's utility and accessibility.

## How It Compares

Think of the existing DAI system but expand it to cover multiple currencies, all while maintaining:
- No central governance.
- No unnecessary fees.
- Multi-collateral backing.

This is what FxDSC aims to offer—a diversified, secure, and scalable stablecoin system.

## Usage

For integration or usage, deploy the respective engine contract for the stablecoin of your interest and interact with its functions as needed.

## Running Tests

Use `forge test` with the `--match-test` option to run specific tests, for example, `forge test --match-test testGetUsdValue`. For verbose output, add `-vvv`, like `forge test --match-test testGetUsdValue -vvv`.

## Safety

Interact only with verified contract addresses. Stay vigilant against imitations and scams. We advise thorough review of the contract codes and third-party audits before production use.

---

Crafted with ❤️ by @fiendlabs. Join our [community](#) for the latest updates and to engage in discussions.
