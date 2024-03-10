// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {USDFFX} from "../src/USDFFX.sol";
import {USDFFXEngine} from "../src/USDFFXEngine.sol";
import {console} from "forge-std/CONSOLE.sol";

contract DeployUSDFFX is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (USDFFX, USDFFXEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!

        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey,
            address deployerAddress
        ) = helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);



        console.log("Deploying USDFFX");

        console.log("Address of this is ", address(this));
        console.log("Address of deployer is ", deployerAddress);

        USDFFX usdffx = new USDFFX(deployerAddress);
        USDFFXEngine usdffxEngine = new USDFFXEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(usdffx)
        );

        console.log("Address of engine is ", address(usdffxEngine));

        // potential solution, pass in my addresss not just my key(deployerKey) and then transfer ownership to the deployer
        usdffx.transferOwnership(address(usdffxEngine));

        vm.stopBroadcast();



        console.log("Owner of USDFFX is ", usdffx.owner());

        return (usdffx, usdffxEngine, helperConfig);
    }
}
