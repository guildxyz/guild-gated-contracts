// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MockERC20 } from "./MockERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/// @title The interface of an ERC677 Receiver contract.
interface ERC677Receiver {
    /// @notice Hook called on token transfers.
    /// @param sender The sender of the tokens.
    /// @param value The amount to be transferred.
    /// @param data The extra data to be passed to the receiving contract.
    function onTokenTransfer(address sender, uint256 value, bytes memory data) external;
}

/// @title A mintable and burnable ERC677 token.
/// @dev Use only for tests.
contract MockERC677 is MockERC20 {
    using Address for address;

    /// @notice Sets metadata.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory symbol) MockERC20(name, symbol) {}

    /// @notice Transfer token to a contract address with additional data if the recipient is a contract.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    /// @param data The extra data to be passed to the receiving contract.
    function transferAndCall(address to, uint256 value, bytes memory data) public returns (bool success) {
        super.transfer(to, value);
        if (to.isContract()) ERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        return true;
    }
}
