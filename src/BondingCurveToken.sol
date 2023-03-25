// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1363.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1363Receiver.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1363Spender.sol";

/**
 * @title ERC1363
 * @dev Implementation of an ERC1363 interface.
 */
contract BondingCurveToken is ERC20, IERC1363, ERC165, IERC1363Receiver, IERC1363Spender {
    using Address for address;

    event TokensReceived(address indexed operator, address indexed sender, uint256 amount, bytes data);

    address public _owner;
    uint8 public _decimals = 18;
    IERC1363 public _reserveToken;

    // TODO: add admins to constructor
    constructor(IERC1363 reserveToken) ERC20("BondingCurveToken", "BCT") {
        _owner = msg.sender;
        _reserveToken = reserveToken;
    }

    modifier onlyOwner() {
        _isOwner();
        _;
    }

    // y = x where x is the supply
    function getCurrentPrice() internal view returns (uint256) {
        return totalSupply();
    }

    /*
    //useful for another curve
    function calculatePrice(uint256 supply) internal pure returns (uint256) {
        return supply * 1;
    }
    */

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // Swap exact reserve for tokens
    function calculateBuyPriceOnlyIn(uint256 amountIn) public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 futureSupply = sqrt(amountIn * 2 + (currentSupply ** 2));
        return futureSupply - currentSupply;
    }

    // TODO: implement swap exact token for reserve, give back additional reserve
    /* 
    function calculatePriceInAndOut(uint256 amountIn, uint256 amountOut) public returns (uint256) {}
    */

    // Swap exact tokens for reserve
    function calculateSellPriceOnlyOut(uint256 amountOut) public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 reserveToPay = (currentSupply ** 2) / 2 - ((currentSupply - amountOut) ** 2) / 2;
        return reserveToPay / 10 ** _decimals;
    }
    /*
    // TODO: Swap tokens for exact reserve
    function calculateSellAmountToGet(uint256 amountToGet) public view returns (uint256) {}
    */

    function buy(uint256 amountIn) public {
        uint256 amountOut = calculateBuyPriceOnlyIn(amountIn * 10 ** _decimals);
        _reserveToken.transferFromAndCall(msg.sender, address(this), amountIn);
        ERC20._mint(msg.sender, amountOut);
    }

    function sell(uint256 amountOut) public {
        uint256 reserveToPay = calculateSellPriceOnlyOut(amountOut);
        _reserveToken.transfer(address(this), reserveToPay);
        ERC20._burn(msg.sender, amountOut);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _isOwner() internal view virtual {
        require(_owner == msg.sender, "OnlyOwner: caller is not the Owner");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1363).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfer tokens to a specified address and then execute a callback on `to`.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAndCall(address to, uint256 amount) public virtual override returns (bool) {
        return transferAndCall(to, amount, "");
    }

    /**
     * @dev Transfer tokens to a specified address and then execute a callback on `to`.
     * @param to The address to transfer to
     * @param amount The amount to be transferred
     * @param data Additional data with no specified format
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAndCall(address to, uint256 amount, bytes memory data) public virtual override returns (bool) {
        transfer(to, amount);
        require(_checkOnTransferReceived(_msgSender(), to, amount, data), "ERC1363: receiver returned wrong data");
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another and then execute a callback on `to`.
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param amount The amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFromAndCall(address from, address to, uint256 amount) public virtual override returns (bool) {
        return transferFromAndCall(from, to, amount, "");
    }

    /**
     * @dev Transfer tokens from one address to another and then execute a callback on `to`.
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param amount The amount of tokens to be transferred
     * @param data Additional data with no specified format
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFromAndCall(address from, address to, uint256 amount, bytes memory data)
        public
        virtual
        override
        returns (bool)
    {
        transferFrom(from, to, amount);
        require(_checkOnTransferReceived(from, to, amount, data), "ERC1363: receiver returned wrong data");
        return true;
    }

    /**
     * @dev Approve spender to transfer tokens and then execute a callback on `spender`.
     * @param spender The address allowed to transfer to
     * @param amount The amount allowed to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(address spender, uint256 amount) public virtual override returns (bool) {
        return approveAndCall(spender, amount, "");
    }

    /**
     * @dev Approve spender to transfer tokens and then execute a callback on `spender`.
     * @param spender The address allowed to transfer to.
     * @param amount The amount allowed to be transferred.
     * @param data Additional data with no specified format.
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(address spender, uint256 amount, bytes memory data)
        public
        virtual
        override
        returns (bool)
    {
        approve(spender, amount);
        require(_checkOnApprovalReceived(spender, amount, data), "ERC1363: spender returned wrong data");
        return true;
    }

    /**
     * @dev Internal function to invoke {IERC1363Receiver-onTransferReceived} on a target address.
     *  The call is not executed if the target address is not a contract.
     * @param sender address Representing the previous owner of the given token amount
     * @param recipient address Target address that will receive the tokens
     * @param amount uint256 The amount mount of tokens to be transferred
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnTransferReceived(address sender, address recipient, uint256 amount, bytes memory data)
        internal
        virtual
        returns (bool)
    {
        if (!recipient.isContract()) {
            revert("ERC1363: transfer to non contract address");
        }

        try IERC1363Receiver(recipient).onTransferReceived(_msgSender(), sender, amount, data) returns (bytes4 retval) {
            return retval == IERC1363Receiver.onTransferReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC1363: transfer to non ERC1363Receiver implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Internal function to invoke {IERC1363Receiver-onApprovalReceived} on a target address.
     *  The call is not executed if the target address is not a contract.
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnApprovalReceived(address spender, uint256 amount, bytes memory data)
        internal
        virtual
        returns (bool)
    {
        if (!spender.isContract()) {
            revert("ERC1363: approve a non contract address");
        }

        try IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data) returns (bytes4 retval) {
            return retval == IERC1363Spender.onApprovalReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC1363: approve a non ERC1363Spender implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data)
        external
        override
        returns (bytes4)
    {
        emit TokensReceived(operator, from, value, data);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function onApprovalReceived(address owner, uint256 value, bytes memory data) external override returns (bytes4) {}
}
