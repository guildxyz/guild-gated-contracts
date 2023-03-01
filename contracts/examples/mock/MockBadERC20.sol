// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MockERC20 } from "./MockERC20.sol";

/// @title An ERC20 token that returns false on transfer.
/// @dev Use only for tests.
contract MockBadERC20 is MockERC20 {
    // solhint-disable-next-line no-empty-blocks
    constructor() MockERC20("MockToken", "MCKT") {}

    /// @dev Same as the regular transfer, but returns false.
    function transfer(address to, uint256 amount) public override returns (bool) {
        super.transfer(to, amount);
        return false;
    }

    /// @dev Same as the regular transferFrom, but returns false.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        super.transferFrom(from, to, amount);
        return false;
    }
}
