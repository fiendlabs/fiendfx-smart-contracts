// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {USDFFX} from "../../src/USDFFX.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract USDFFXTest is StdCheats, Test {
    USDFFX usdffx;
    address owner;

    function setUp() public {
        owner = address(this);
        usdffx = new USDFFX(owner);
    }

    function testConstructor() public {
        assertEq(usdffx.name(), "USDFFX");
        assertEq(usdffx.symbol(), "USDFFX");
    }

    function testMustMintMoreThanZero() public {
        vm.prank(usdffx.owner());
        vm.expectRevert();
        usdffx.mint(address(this), 0);
    }

    function testMustBurnMoreThanZero() public {
        vm.startPrank(usdffx.owner());
        usdffx.mint(address(this), 100);
        vm.expectRevert();
        usdffx.burn(0);
        vm.stopPrank();
    }

    function testCantBurnMoreThanYouHave() public {
        vm.startPrank(usdffx.owner());
        usdffx.mint(address(this), 100);
        vm.expectRevert();
        usdffx.burn(101);
        vm.stopPrank();
    }

    function testCantMintToZeroAddress() public {
        vm.startPrank(usdffx.owner());
        vm.expectRevert();
        usdffx.mint(address(0), 100);
        vm.stopPrank();
    }
}
