// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SanctionToken.sol";

contract SanctionTokenTest is Test {
    SanctionToken public sanctionToken;
    address owner;
    address admin0;
    address admin1;
    address sanctionedUser;
    address testUser;
    address[] toSanction = new address[](1);
    address[] adminsList = new address[](2);
    uint256 decimals = 10**18;
    
    function setUp() public {
        owner = address(this);
        admin0 = address(0);
        admin1 = address(1);
        sanctionedUser = address(2);
        testUser = address(3);
        toSanction[0] = sanctionedUser;
        adminsList[0] = admin0;
        adminsList[1] = admin1;

        sanctionToken = new SanctionToken(adminsList);
    }

    function testSetUp() public {
        assertEq(sanctionToken.totalSupply(), 1500*decimals);
    }

    function testTransfers() public {
        sanctionToken.transfer(sanctionedUser, 100*decimals);
        assertEq(sanctionToken.balanceOf(owner), 1400*decimals);
        assertEq(sanctionToken.balanceOf(sanctionedUser), 100*decimals);
    }

    function testNotAllowedSanctioning() public {
        vm.expectRevert("OnlyAdmin: caller is not an Admin");
        vm.prank(testUser);
        sanctionToken.sanction(toSanction);
        assertEq(sanctionToken.isSanctioned(sanctionedUser), false);
    }

    function testSetAdmin() public {
        assertEq(sanctionToken.isAdmin(testUser), false);
        sanctionToken.setAdmin(testUser);
        assertEq(sanctionToken.isAdmin(testUser), true);
    }

    function testSanctioning() public { 
        assertEq(sanctionToken.isSanctioned(sanctionedUser), false);
        vm.prank(admin0);
        sanctionToken.sanction(toSanction);
        assertEq(sanctionToken.isSanctioned(sanctionedUser), true);
    }

    function testReceiveAsSanctioned() public {
        testSanctioning();
        vm.expectRevert("Sanctioned: Cannot transfer to or from a sanctioned address");
        sanctionToken.transfer(sanctionedUser, 200*decimals);
    }

    function testSendAsSanctioned() public {
        testSanctioning();
        vm.prank(sanctionedUser);
        vm.expectRevert("Sanctioned: Cannot transfer to or from a sanctioned address");
        sanctionToken.transfer(testUser, 200*decimals);
    }

    function testUnsanction() public {
        testSanctioning();
        vm.prank(admin0);
        sanctionToken.unsanction(sanctionedUser);
        assertEq(sanctionToken.isSanctioned(sanctionedUser), false);
    }

    function testUnsanctionAndSend() public {
        testTransfers();
        testUnsanction(); 
        vm.prank(sanctionedUser);
        sanctionToken.transfer(owner, 100*decimals);
        assertEq(sanctionToken.balanceOf(owner), 1500*decimals);
        assertEq(sanctionToken.balanceOf(sanctionedUser), 0);
    }
}
