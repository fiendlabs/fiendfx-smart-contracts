// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployUSDFFX} from "../../script/DeployUSDFFX.s.sol";
import {USDFFXEngine} from "../../src/USDFFXEngine.sol";
import {USDFFX} from "../../src/USDFFX.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockFailedTransferFrom} from "../mocks/MockFailedTransferFrom.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract USDFFXEngineTest is StdCheats, Test {
    event CollateralRedeemed(
        address indexed redeemFrom,
        address indexed redeemTo,
        address token,
        uint256 amount
    ); // if redeemFrom != redeemedTo, then it was liquidated

    USDFFXEngine public usdffxEngine;
    USDFFX public usdffx;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;
    address public deployerAddress;

    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    address public user = address(1);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;

    // Liquidation
    address public liquidator = makeAddr("liquidator");
    uint256 public collateralToCover = 20 ether;

    function setUp() external {
        DeployUSDFFX deployer = new DeployUSDFFX();
        (usdffx, usdffxEngine, helperConfig) = deployer.run();
        (
            ethUsdPriceFeed,
            btcUsdPriceFeed,
            weth,
            wbtc,
            deployerKey,
            deployerAddress
        ) = helperConfig.activeNetworkConfig();
        if (block.chainid == 31337) {
            vm.deal(user, STARTING_USER_BALANCE);
        }

        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    ///////////////////////
    // Constructor Tests //
    ///////////////////////

    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(
            USDFFXEngine
                .USDFFXEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch
                .selector
        );
        new USDFFXEngine(tokenAddresses, feedAddresses, address(usdffx));
    }

    //////////////////
    // Price Tests //
    //////////////////

    function testGetTokenAmountFromUsd() public {
        // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
        uint256 expectedWeth = 0.05 ether;
        uint256 amountWeth = usdffxEngine.getTokenAmountFromUsd(weth, 100e18);
        assertEq(amountWeth, expectedWeth);
    }

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 ETH * $2000/ETH = $30,000e18
        uint256 expectedUsd = 30000e18;
        uint256 usdValue = usdffxEngine.getUsdValue(weth, ethAmount);
        assertEq(usdValue, expectedUsd);
    }

    ///////////////////////////////////////
    // depositCollateral Tests //
    ///////////////////////////////////////

    // this test needs it's own setup
    function testRevertsIfTransferFromFails() public {
        // Arrange - Setup
        address owner = msg.sender;
        vm.prank(owner);
        MockFailedTransferFrom mockUsdffx = new MockFailedTransferFrom(
            address(owner)
        );
        tokenAddresses = [address(mockUsdffx)];
        feedAddresses = [ethUsdPriceFeed];
        vm.prank(owner);
        USDFFXEngine mockUsdffxEngine = new USDFFXEngine(
            tokenAddresses,
            feedAddresses,
            address(mockUsdffx)
        );
        mockUsdffx.mint(user, amountCollateral);

        vm.prank(owner);
        mockUsdffx.transferOwnership(address(mockUsdffxEngine));
        // Arrange - User
        vm.startPrank(user);
        ERC20Mock(address(mockUsdffx)).approve(
            address(mockUsdffxEngine),
            amountCollateral
        );
        // Act / Assert
        vm.expectRevert(USDFFXEngine.USDFFXEngine__TransferFailed.selector);
        mockUsdffxEngine.depositCollateral(
            address(mockUsdffx),
            amountCollateral
        );
        vm.stopPrank();
    }

    function testRevertsIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(usdffxEngine), amountCollateral);

        vm.expectRevert(USDFFXEngine.USDFFXEngine__NeedsMoreThanZero.selector);
        usdffxEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock();
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                USDFFXEngine.USDFFXEngine__TokenNotAllowed.selector,
                address(randToken)
            )
        );
        usdffxEngine.depositCollateral(address(randToken), amountCollateral);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(usdffxEngine), amountCollateral);
        usdffxEngine.depositCollateral(weth, amountCollateral);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralWithoutMinting()
        public
        depositedCollateral
    {
        uint256 userBalance = usdffx.balanceOf(user);
        assertEq(userBalance, 0);
    }

    function testCanDepositedCollateralAndGetAccountInfo()
        public
        depositedCollateral
    {
        (uint256 totalUsdffxMinted, uint256 collateralValueInUsd) = usdffxEngine
            .getAccountInformation(user);
        uint256 expectedDepositedAmount = usdffxEngine.getTokenAmountFromUsd(
            weth,
            collateralValueInUsd
        );
        assertEq(totalUsdffxMinted, 0);
        assertEq(expectedDepositedAmount, amountCollateral);
    }

    ///////////////////////////////////////
    // depositCollateralAndMintUsdffx Tests //
    ///////////////////////////////////////

    function testRevertsIfMintedUsdffxBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountToMint = (amountCollateral * (uint256(price) * usdffxEngine.getAdditionalFeedPrecision())) / usdffxEngine.getPrecision();
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(usdffxEngine), amountCollateral);

        uint256 expectedHealthFactor =
        usdffxEngine.calculateHealthFactor(amountToMint, usdffxEngine.getUsdValue(weth, amountCollateral));
        vm.expectRevert(abi.encodeWithSelector(USDFFXEngine.USDFFXEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        usdffxEngine.depositCollateralAndMintUsdffx(weth, amountCollateral, amountToMint);
        vm.stopPrank();
    }

    modifier depositedCollateralAndMintedUsdffx() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(usdffxEngine), amountCollateral);
        usdffxEngine.depositCollateralAndMintUsdffx(weth, amountCollateral, amountToMint);
        vm.stopPrank();
        _;
    }

        function testCanMintWithDepositedCollateral() public depositedCollateralAndMintedUsdffx {
        uint256 userBalance = usdffx.balanceOf(user);
        assertEq(userBalance, amountToMint);
    }
}
