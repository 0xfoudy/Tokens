// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BondingCurveToken.sol";
import "./SanctionToken.sol";


contract EchidnaBonding {
  BondingCurveToken bondingToken;
  SanctionToken reserveToken;
  address[] adminList = new address[](1);
    /* ================================================================
       Events used for debugging or showing information.
       ================================================================ */
    event Value(string reason, uint256 val);
    event LogErr(bytes error);
    event Debug(int128, int128);
    event Addy(address);

  // setup
  constructor() {
    adminList[0] = address(this);
    reserveToken = new SanctionToken(adminList);
    bondingToken = new BondingCurveToken(reserveToken);
  }

  function testBuying(uint _amountIn) public{
    // Pre conditions
    _amountIn = 1 + (_amountIn % 1500);
    // Action
    uint256 preBuyAmountToReceive = bondingToken.calculateBuyPriceOnlyIn(_amountIn * 10**18);
    uint256 oldSupply = bondingToken.totalSupply();
    reserveToken.approve(address(bondingToken), _amountIn);
    try bondingToken.buy(_amountIn){
      assert(preBuyAmountToReceive > bondingToken.calculateBuyPriceOnlyIn(_amountIn * 10**18));
      assert(oldSupply + preBuyAmountToReceive == bondingToken.totalSupply());
    } catch (bytes memory err) {
      assert(false);
    }
  }

  function testSelling(uint _amountOut) public{
    // Pre conditions
    _amountOut = 1 + (_amountOut % bondingToken.balanceOf(address(this)));
    // Action
    uint256 preSellPrice = bondingToken.calculateSellPriceOnlyOut(_amountOut * 10**18);
    uint256 preSellSupply = bondingToken.totalSupply();
    try bondingToken.sell(_amountOut){
      assert(preSellPrice < bondingToken.calculateSellPriceOnlyOut(_amountOut * 10**18));
      assert(preSellSupply + preSellPrice == bondingToken.totalSupply());
    } catch (bytes memory err) {
      assert(false);
    }
  }

}
