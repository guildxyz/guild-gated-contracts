// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { GuildOracle } from "../GuildOracle.sol";
import { IGatedERC721 } from "./interfaces/IGatedERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title An ERC721 token that can be claimed only by those holding a specific role on guild.xyz.
contract GatedERC721 is GuildOracle, ERC721, IGatedERC721, Ownable {
    using Strings for uint256;

    uint96 public immutable rewardedRole;

    uint256 public immutable maxSupply;
    uint256 public totalSupply;
    /// @notice The ipfs hash, under which the off-chain metadata is uploaded.
    string internal cid;

    mapping(address => bool) public hasClaimed;

    /// @notice Sets metadata and the oracle details.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param cid_ The ipfs hash, under which the off-chain metadata is uploaded.
    /// @param maxSupply_ The maximum number of NFTs that can ever be minted.
    /// @param guildId The id of the guild the rewarded role is in.
    /// @param rewardedRole_ The id of the rewarded role on Guild.
    /// @param linkToken The address of the Chainlink token.
    /// @param oracleAddress The address of the oracle processing the requests.
    /// @param jobId The id of the job to run on the oracle.
    /// @param oracleFee The amount of tokens to forward to the oracle with every request.
    constructor(
        string memory name,
        string memory symbol,
        string memory cid_,
        uint256 maxSupply_,
        string memory guildId,
        uint96 rewardedRole_,
        address linkToken,
        address oracleAddress,
        bytes32 jobId,
        uint256 oracleFee
    ) GuildOracle(linkToken, oracleAddress, jobId, oracleFee, guildId) ERC721(name, symbol) {
        if (maxSupply_ == 0) revert MaxSupplyZero();

        cid = cid_;
        maxSupply = maxSupply_;
        rewardedRole = rewardedRole_;
    }

    function claim() external override {
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256 tokenId = totalSupply;
        if (tokenId >= maxSupply) revert TokenIdOutOfBounds(tokenId, maxSupply);

        requestAccessCheck(msg.sender, rewardedRole, this.fulfillClaim.selector, abi.encode(msg.sender, tokenId));

        emit ClaimRequested(msg.sender);
    }

    /// @dev The actual claim function called by the oracle if the requirements are fulfilled.
    function fulfillClaim(bytes32 requestId, uint256 access) public checkRole(requestId, access) {
        (address receiver, uint256 tokenId) = abi.decode(requests[requestId].args, (address, uint256));

        // Mark it claimed and mint the token.
        hasClaimed[receiver] = true;
        _safeMint(receiver, tokenId);

        emit Claimed(receiver);
    }

    /// An optimized version of {_safeMint} using custom errors.
    function _safeMint(address to, uint256 tokenId) internal override {
        if (tokenId >= maxSupply) revert TokenIdOutOfBounds(tokenId, maxSupply);
        unchecked {
            ++totalSupply;
        }
        _safeMint(to, tokenId, "");
    }

    /// @inheritdoc IERC721Metadata
    /// @param tokenId The id of the token.
    function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken(tokenId);
        return string.concat("ipfs://", cid, "/", tokenId.toString(), ".json");
    }
}
