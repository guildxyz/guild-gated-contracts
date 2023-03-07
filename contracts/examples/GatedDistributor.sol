//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IGatedDistributor } from "./interfaces/IGatedDistributor.sol";
import { GuildOracle } from "../GuildOracle.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A Guild-gated ERC20 distributor.
contract GatedDistributor is IGatedDistributor, GuildOracle, Ownable {
    uint256 public immutable guildId;
    uint256 public immutable rewardedRole;
    address public immutable rewardToken;
    uint128 public immutable rewardAmount;
    uint128 public distributionEnd;

    mapping(address => mapping(GuildAction => bool)) public hasClaimed;

    /// @notice Sets the config and the oracle details.
    /// @param token_ The address of the ERC20 token to distribute.
    /// @param amount_ The amount of tokens an eligible address will be able to claim.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    /// @param guildId_ The id of the guild the rewarded role is in.
    /// @param rewardedRole_ The id of the rewarded role on Guild.
    /// @param linkToken The address of the Chainlink token.
    /// @param oracleAddress The address of the oracle processing the requests.
    /// @param jobId The id of the job to run on the oracle.
    /// @param oracleFee The amount of tokens to forward to the oracle with every request.
    constructor(
        address token_,
        uint128 amount_,
        uint256 distributionDuration,
        uint256 guildId_,
        uint256 rewardedRole_,
        address linkToken,
        address oracleAddress,
        bytes32 jobId,
        uint256 oracleFee
    ) GuildOracle(linkToken, oracleAddress, jobId, oracleFee) {
        if (
            token_ == address(0) ||
            amount_ == 0 ||
            distributionDuration == 0 ||
            linkToken == address(0) ||
            oracleAddress == address(0)
        ) revert InvalidParameters();

        guildId = guildId_;
        rewardedRole = rewardedRole_;
        rewardToken = token_;
        rewardAmount = amount_;
        distributionEnd = uint128(block.timestamp + distributionDuration);
    }

    function claim(GuildAction guildAction) external {
        if (block.timestamp > distributionEnd) revert DistributionEnded(block.timestamp, distributionEnd);
        if (hasClaimed[msg.sender][guildAction]) revert AlreadyClaimed();
        if (IERC20(rewardToken).balanceOf(address(this)) < rewardAmount) revert OutOfTokens();

        if (guildAction == GuildAction.HAS_ACCESS)
            requestGuildRoleAccessCheck(
                msg.sender,
                rewardedRole,
                guildId,
                this.fulfillClaim.selector,
                abi.encode(msg.sender, GuildAction.HAS_ACCESS)
            );
        else if (guildAction == GuildAction.HAS_ROLE)
            requestGuildRoleCheck(
                msg.sender,
                rewardedRole,
                this.fulfillClaim.selector,
                abi.encode(msg.sender, GuildAction.HAS_ROLE)
            );
        else if (guildAction == GuildAction.IS_ADMIN)
            requestGuildAdminCheck(
                msg.sender,
                guildId,
                this.fulfillClaim.selector,
                abi.encode(msg.sender, GuildAction.IS_ADMIN)
            );
        else if (guildAction == GuildAction.IS_OWNER)
            requestGuildOwnerCheck(
                msg.sender,
                guildId,
                this.fulfillClaim.selector,
                abi.encode(msg.sender, GuildAction.IS_OWNER)
            );
        else if (guildAction == GuildAction.JOINED_GUILD)
            requestGuildJoinCheck(
                msg.sender,
                guildId,
                this.fulfillClaim.selector,
                abi.encode(msg.sender, GuildAction.JOINED_GUILD)
            );

        emit ClaimRequested(msg.sender, guildAction);
    }

    /// @dev The actual claim function called by the oracle if the requirements are fulfilled.
    function fulfillClaim(bytes32 requestId, uint256 access) public checkResponse(requestId, access) {
        (address receiver, GuildAction guildAction) = abi.decode(requests[requestId].args, (address, GuildAction));

        // Mark it claimed and send the rewardToken.
        hasClaimed[receiver][guildAction] = true;
        if (!IERC20(rewardToken).transfer(receiver, rewardAmount))
            revert TransferFailed(rewardToken, address(this), receiver);

        emit Claimed(receiver, guildAction);
    }

    function prolongDistributionPeriod(uint128 additionalSeconds) external onlyOwner {
        uint128 newDistributionEnd = distributionEnd + additionalSeconds;
        distributionEnd = newDistributionEnd;
        emit DistributionProlonged(newDistributionEnd);
    }

    function withdraw(address recipient) external onlyOwner {
        if (block.timestamp <= distributionEnd) revert DistributionOngoing(block.timestamp, distributionEnd);
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (balance == 0) revert AlreadyWithdrawn();
        if (!IERC20(rewardToken).transfer(recipient, balance))
            revert TransferFailed(rewardToken, address(this), recipient);
        emit Withdrawn(recipient, balance);
    }
}
