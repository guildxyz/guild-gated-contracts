// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @title An ERC721 token that can be claimed based on fulfilling specific criteria on guild.xyz.
interface IGatedERC721 is IERC721Metadata {
    /// @notice Actions that can be checked via the oracle.
    enum GuildAction {
        HAS_ACCESS,
        HAS_ROLE,
        IS_ADMIN,
        IS_OWNER,
        JOINED_GUILD
    }

    /// @notice Returns true if the address has already claimed their token.
    /// @param account The user's address.
    /// @param guildAction The action which has been checked via the oracle.
    /// @return claimed Whether the address has claimed their token.
    function hasClaimed(address account, GuildAction guildAction) external view returns (bool claimed);

    /// @notice The maximum number of NFTs that can ever be minted.
    /// @return count The number of NFTs.
    function maxSupply() external view returns (uint256 count);

    /// @notice Returns the id of the guild the rewarded role(s) is/are in.
    /// @return guild The id of the guild.
    function guildId() external view returns (uint256 guild);

    /// @notice Returns the id of the role in Guild.
    /// @return role The id of the role.
    function rewardedRole() external view returns (uint256 role);

    /// @notice The total amount of tokens stored by the contract.
    /// @return count The number of NFTs.
    function totalSupply() external view returns (uint256 count);

    /// @notice Claims tokens to the given address.
    /// @param guildAction The action to check via the oracle.
    function claim(GuildAction guildAction) external;

    /// @notice Event emitted whenever a claim succeeds (is fulfilled).
    /// @param receiver The address that received the tokens.
    /// @param guildAction The action to check via the oracle.
    event Claimed(address receiver, GuildAction guildAction);

    /// @notice Event emitted whenever a claim is requested.
    /// @param receiver The address that receives the tokens.
    /// @param guildAction The action that has been checked via the oracle.
    event ClaimRequested(address receiver, GuildAction guildAction);

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
