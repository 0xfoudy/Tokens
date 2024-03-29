// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1363.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1363Receiver.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1363Spender.sol";

/**
 * @title ERC1363
 * @dev Implementation of an ERC1363 interface.
 */
contract SanctionToken is ERC20, IERC1363, ERC165 {
    using Address for address;

    address public _owner;
    uint8 public _decimals = 18;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _sanctioned;

    constructor(address[] memory admins) ERC20("SanctionToken", "SANCTION") {
        ERC20._mint(msg.sender, 1500 * 10 ** _decimals);
        _owner = msg.sender;
        for (uint256 i = 0; i < admins.length; ++i) {
            setAdmin(admins[i]);
        }
    }

    modifier onlyAdmin() {
        _isAdmin();
        _;
    }

    modifier onlyOwner() {
        _isOwner();
        _;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _isOwner() internal view virtual {
        require(_owner == msg.sender, "OnlyOwner: caller is not the Owner");
    }

    function _isAdmin() internal view virtual {
        require(isAdmin(msg.sender), "OnlyAdmin: caller is not an Admin");
    }

    function setAdmin(address addy) public onlyOwner {
        _admins[addy] = true;
    }

    function removeAdmin(address addy) public onlyOwner {
        delete _admins[addy];
    }

    function isAdmin(address addy) public view returns (bool) {
        return _admins[addy];
    }

    function sanction(address[] memory addies) public onlyAdmin {
        for (uint256 i = 0; i < addies.length; ++i) {
            _sanctioned[addies[i]] = true;
        }
    }

    function unsanction(address addy) public onlyAdmin {
        delete _sanctioned[addy];
    }

    function isSanctioned(address addy) public view returns (bool) {
        return _sanctioned[addy];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        require(!isSanctioned(from) && !isSanctioned(to), "Sanctioned: Cannot transfer to or from a sanctioned address");
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
}
