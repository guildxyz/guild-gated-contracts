// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title A mintable and burnable ERC20 token.
/// @dev Use only for tests.
contract MockERC20 is ERC20 {
    /// @notice Sets metadata.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @notice Mint `amount` of tokens to `account`.
    /// @param account The address of the account receiving the tokens.
    /// @param amount The amount of tokens the account receives.
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /// @notice Burn `amount` of tokens from `account`.
    /// @param account The address of the account to burn tokens from.
    /// @param amount The amount of tokens to burn in wei.
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
