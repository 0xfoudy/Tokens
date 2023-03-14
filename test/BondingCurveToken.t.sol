// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SanctionToken.sol";
import "../src/BondingCurveToken.sol";

contract BondingCurveTokenTest is Test {
    SanctionToken sanctionToken;
    BondingCurveToken bondingCurveToken;
    address owner;
    address admin;
    address testUser;
    address[] adminsList = new address[](1);
    uint256 decimals = 10 ** 18;

    function setUp() public {
        owner = address(this);
        admin = address(0);
        testUser = address(1);
        adminsList[0] = admin;

        sanctionToken = new SanctionToken(adminsList);
        bondingCurveToken = new BondingCurveToken(sanctionToken);
    }

    function testSetUp() public {
        assertEq(sanctionToken.totalSupply(), 1500 * decimals);
        assertEq(sanctionToken.balanceOf(owner), 1500 * decimals);
        assertEq(bondingCurveToken.totalSupply(), 0 * decimals);
    }

    function testBuy() public {
        sanctionToken.approve(address(bondingCurveToken), 10 * decimals);
        bondingCurveToken.buy(10 * decimals);
        // total received should be sqrt(20)
        assertEq(bondingCurveToken.balanceOf(owner), 4_472_135_954_999_579_392);
        assertEq(bondingCurveToken.totalSupply(), 4_472_135_954_999_579_392);
        sanctionToken.approve(address(bondingCurveToken), 10 * decimals);
        bondingCurveToken.buy(10 * decimals);
        // total supply should be sqrt(40), received last tx should be sqrt(40) - sqrt(20)
        assertEq(bondingCurveToken.balanceOf(owner), 6_324_555_320_336_758_663);
        assertEq(bondingCurveToken.totalSupply(), 6_324_555_320_336_758_663);
    }

    function testSell() public {
        sanctionToken.approve(address(bondingCurveToken), 10 * decimals);
        bondingCurveToken.buy(10 * decimals);
        assert(bondingCurveToken.balanceOf(owner) > 0);
        bondingCurveToken.sell(4_472_135_954_999_579_392);
        assert(bondingCurveToken.balanceOf(owner) == 0);
    }
}
