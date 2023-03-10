// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SanctionToken.sol";
import "forge-std/console.sol";

contract SanctionTokenTest is Test {
    SanctionToken public sanctionToken;
    address owner;
    address admin0;
    address admin1;
    address user2;
    address user3;

    function setUp() public {
        sanctionToken = new SanctionToken();
        owner = address(this);
        admin0 = address(0);
        admin1 = address(1);
        user2 = address(2);
        user3 = address(3);
    }

    function testSetUp() public {
        assertEq(sanctionToken.totalSupply(), 1500);
    }

    function testTransfers() public {
        sanctionToken.transfer(user2, 100);
        assertEq(sanctionToken.balanceOf(owner), 1400);

        assertEq(sanctionToken.balanceOf(user2), 100);
    }

    function testBlacklisting() public {
        vm.prank(admin0);
        address[] memory toBlacklist = new address[](1);
        toBlacklist[0] = user2;
        sanctionToken.blackList(toBlacklist);

        assertEq(sanctionToken.isBlacklisted(user2), false);
    }

    // function testIncrement() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
