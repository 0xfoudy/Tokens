// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GodModeToken.sol";

contract GodModeTokenTest is Test {
    GodModeToken public godModeToken;
    address owner;
    address zeus;
    address poseidon;
    address peasant;
    address testUser;
    address[] godsList = new address[](2);
    uint256 decimals = 10 ** 18;

    function setUp() public {
        owner = address(this);
        zeus = address(0);
        poseidon = address(1);
        peasant = address(2);
        testUser = address(3);
        godsList[0] = zeus;
        godsList[1] = poseidon;

        godModeToken = new GodModeToken(godsList);
    }

    function testSetUp() public {
        assertEq(godModeToken.totalSupply(), 1500 * decimals);
    }

    function testTransfers() public {
        godModeToken.transfer(peasant, 100 * decimals);
        assertEq(godModeToken.balanceOf(owner), 1400 * decimals);
        assertEq(godModeToken.balanceOf(peasant), 100 * decimals);
    }

    function testSetGod() public {
        godModeToken.setGods(testUser);
        assertEq(godModeToken.isGod(testUser), true);
    }

    function testRemoveGod() public {
        testSetGod();
        godModeToken.removeGod(testUser);
        assertEq(godModeToken.isGod(testUser), false);
    }

    function testPeasantTransfer() public {
        testTransfers();
        vm.expectRevert("ERC20: insufficient allowance");
        godModeToken.transferFrom(peasant, owner, 100 * decimals);
    }

    function testGodTransfer() public {
        testTransfers();
        vm.prank(zeus);
        godModeToken.transferFrom(peasant, owner, 100 * decimals);
        assertEq(godModeToken.balanceOf(owner), 1500 * decimals);
        assertEq(godModeToken.balanceOf(peasant), 0);
    }
}
