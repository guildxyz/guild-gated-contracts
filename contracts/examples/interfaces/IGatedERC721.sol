// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @title An ERC721 token that can be claimed only by those holding a specific role on guild.xyz.
interface IGatedERC721 is IERC721Metadata {
    /// @notice Returns true if the address has already claimed their token.
    /// @param account The user's address.
    /// @return claimed Whether the address has claimed their token.
    function hasClaimed(address account) external view returns (bool claimed);

    /// @notice The maximum number of NFTs that can ever be minted.
    /// @return count The number of NFTs.
    function maxSupply() external view returns (uint256 count);

    /// @notice Returns the id of the role in Guild.
    /// @return role The id of the role.
    function rewardedRole() external view returns (uint96 role);

    /// @notice The total amount of tokens stored by the contract.
    /// @return count The number of NFTs.
    function totalSupply() external view returns (uint256 count);

    /// @notice Claims tokens to the given address.
    function claim() external;

    /// @notice Event emitted whenever a claim succeeds (is fulfilled).
    /// @param receiver The address that received the tokens.
    event Claimed(address receiver);

    /// @notice Event emitted whenever a claim is requested.
    /// @param receiver The address that receives the tokens.
    event ClaimRequested(address receiver);

    /// @notice Error thrown when the token is already claimed.
    error AlreadyClaimed();

    /// @notice Error thrown when the maximum supply attempted to be set is zero.
    error MaxSupplyZero();

    /// @notice Error thrown when trying to query info about a token that's not (yet) minted.
    /// @param tokenId The queried id.
    error NonExistentToken(uint256 tokenId);

    /// @notice Error thrown when the tokenId is higher than the maximum supply.
    /// @param tokenId The id that was attempted to be used.
    /// @param maxSupply The maximum supply of the token.
    error TokenIdOutOfBounds(uint256 tokenId, uint256 maxSupply);
}
