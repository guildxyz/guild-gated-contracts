//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IGatedDistributor } from "./interfaces/IGatedDistributor.sol";
import { RequestGuildRole } from "./RequestGuildRole.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A Guild-gated ERC20 distributor.
contract GatedDistributor is IGatedDistributor, RequestGuildRole, Ownable {
    /// @inheritdoc IGatedDistributor
    uint96 public immutable rewardedRole;
    /// @inheritdoc IGatedDistributor
    address public immutable rewardToken;
    /// @inheritdoc IGatedDistributor
    uint128 public immutable rewardAmount;
    /// @inheritdoc IGatedDistributor
    uint128 public distributionEnd;

    /// @inheritdoc IGatedDistributor
    mapping(address => bool) public hasClaimed;

    /// @notice Sets the config and the oracle details.
    /// @param token_ The address of the ERC20 token to distribute.
    /// @param amount_ The amount of tokens an eligible address will be able to claim.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    /// @param guildId The id of the guild the rewarded role is in.
    /// @param rewardedRole_ The id of the rewarded role on Guild.
    /// @param linkToken The address of the Chainlink token.
    /// @param oracleAddress The address of the oracle processing the requests.
    /// @param jobId The id of the job to run on the oracle.
    /// @param oracleFee The amount of tokens to forward to the oracle with every request.
    constructor(
        address token_,
        uint128 amount_,
        uint256 distributionDuration,
        string memory guildId,
        uint96 rewardedRole_,
        address linkToken,
        address oracleAddress,
        bytes32 jobId,
        uint256 oracleFee
    ) RequestGuildRole(linkToken, oracleAddress, jobId, oracleFee, guildId) {
        if (
            token_ == address(0) ||
            amount_ == 0 ||
            distributionDuration == 0 ||
            linkToken == address(0) ||
            oracleAddress == address(0)
        ) revert InvalidParameters();

        rewardedRole = rewardedRole_;
        rewardToken = token_;
        rewardAmount = amount_;
        distributionEnd = uint128(block.timestamp + distributionDuration);
    }

    /// @inheritdoc IGatedDistributor
    function claim() external {
        if (block.timestamp > distributionEnd) revert DistributionEnded(block.timestamp, distributionEnd);
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (IERC20(rewardToken).balanceOf(address(this)) < rewardAmount) revert OutOfTokens();

        requestAccessCheck(msg.sender, rewardedRole, this.fulfillClaim.selector, abi.encode(msg.sender));

        emit ClaimRequested(msg.sender);
    }

    /// @dev The actual claim function called by the oracle if the requirements are fulfilled.
    function fulfillClaim(bytes32 requestId, uint256 access) public checkRole(requestId, access) {
        // Note: requests[requestId].userAddress could be used, this is just for demonstrating this feature.
        address receiver = abi.decode(requests[requestId].args, (address));

        // Mark it claimed and send the rewardToken.
        hasClaimed[receiver] = true;
        if (!IERC20(rewardToken).transfer(receiver, rewardAmount))
            revert TransferFailed(rewardToken, address(this), receiver);

        emit Claimed(receiver);
    }

    /// @inheritdoc IGatedDistributor
    function prolongDistributionPeriod(uint128 additionalSeconds) external onlyOwner {
        uint128 newDistributionEnd = distributionEnd + additionalSeconds;
        distributionEnd = newDistributionEnd;
        emit DistributionProlonged(newDistributionEnd);
    }

    /// @inheritdoc IGatedDistributor
    function withdraw(address recipient) external onlyOwner {
        if (block.timestamp <= distributionEnd) revert DistributionOngoing(block.timestamp, distributionEnd);
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (balance == 0) revert AlreadyWithdrawn();
        if (!IERC20(rewardToken).transfer(recipient, balance))
            revert TransferFailed(rewardToken, address(this), recipient);
        emit Withdrawn(recipient, balance);
    }
}
