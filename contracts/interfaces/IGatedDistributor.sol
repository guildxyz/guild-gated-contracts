// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Provides ERC20 token distribution based on a Merkle tree.
interface IGatedDistributor {
    /// @notice Returns the id of the role in Guild.
    /// @return role The id of the role.
    function rewardedRole() external view returns (uint96 role);

    /// @notice Returns the address of the token distributed by this contract.
    /// @return tokenAddress The address of the token.
    function token() external view returns (address tokenAddress);

    /// @notice Returns the amount of tokens an eligible address can claim.
    /// @return tokenAmount The amount in wei.
    function amount() external view returns (uint128 tokenAmount);

    /// @notice Returns the unix timestamp that marks the end of the token distribution.
    /// @return unixSeconds The unix timestamp in seconds.
    function distributionEnd() external view returns (uint128 unixSeconds);

    /// @notice Returns true if the address has already claimed.
    /// @param account User addresses.
    /// @return claimed Whether the address has claimed their tokens.
    function hasClaimed(address account) external view returns (bool claimed);

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param guildIndex The index of the Guild from the membership endpoint. Temporary solution.
    function claim(uint256 guildIndex) external;

    /// @notice Prolongs the distribution period of the tokens. Callable only by the owner.
    /// @param additionalSeconds The seconds to add to the current distributionEnd.
    function prolongDistributionPeriod(uint128 additionalSeconds) external;

    /// @notice Sends the tokens remaining after the distribution has ended to `recipient`. Callable only by the owner.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a claim succeeds.
    /// @param receiver The address that received the tokens.
    event Claimed(address receiver);

    /// @notice This event is triggered whenever a call to {prolongDistributionPeriod} succeeds.
    /// @param newDistributionEnd The time when the distribution ends.
    event DistributionProlonged(uint128 newDistributionEnd);

    /// @notice This event is triggered whenever a call to {withdraw} succeeds.
    /// @param account The address that received the tokens.
    /// @param amount The amount of tokens the address received.
    event Withdrawn(address account, uint256 amount);

    /// @notice Error thrown when there's nothing to withdraw.
    error AlreadyWithdrawn();

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    error DistributionOngoing(uint256 current, uint256 end);

    /// @notice Error thrown when the drop is already claimed.
    error AlreadyClaimed();

    /// @notice Error thrown when a function receives invalid parameters.
    error InvalidParameters();

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();

    /// @notice Error thrown when a function is called by anyone but the oracle.
    error OnlyOracle();

    /// @notice Error thrown when the contract has less tokens than needed for a claim.
    error OutOfTokens();

    /// @notice Error thrown when a transfer failed.
    /// @param token The address of token attempted to be transferred.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address token, address from, address to);
}
