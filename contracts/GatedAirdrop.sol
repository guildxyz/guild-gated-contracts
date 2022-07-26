//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IGatedAirdrop } from "./interfaces/IGatedAirdrop.sol";
import { RequestGuildRole } from "./RequestGuildRole.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A Guild-gated ERC20 airdrop.
contract GatedAirdrop is IGatedAirdrop, RequestGuildRole, Ownable {
    /// @inheritdoc IGatedAirdrop
    uint96 public immutable rewardedRole;
    /// @inheritdoc IGatedAirdrop
    address public immutable token;
    /// @inheritdoc IGatedAirdrop
    uint128 public immutable amount;
    /// @inheritdoc IGatedAirdrop
    uint128 public distributionEnd;

    /// @inheritdoc IGatedAirdrop
    mapping(address => bool) public hasClaimed;

    /// @notice Sets the config and the oracle details.
    /// @param token_ The address of the ERC20 token to distribute.
    /// @param amount_ The amount of tokens an eligible address will be able to claim.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    /// @param rewardedRole_ The Guild id of the rewarded role.
    /// @param linkToken The address of the Chainlink token.
    /// @param oracleAddress The address of the oracle processing requests.
    /// @param jobId The id of the oracle job.
    /// @param oracleFee The amount of tokens the oracle needs for every request.
    constructor(
        address token_,
        uint128 amount_,
        uint256 distributionDuration,
        uint96 rewardedRole_,
        address linkToken,
        address oracleAddress,
        bytes32 jobId,
        uint256 oracleFee
    ) RequestGuildRole(linkToken, oracleAddress, jobId, oracleFee) {
        if (token_ == address(0)) revert InvalidParameters();

        rewardedRole = rewardedRole_;
        token = token_;
        amount = amount_;
        distributionEnd = uint128(block.timestamp + distributionDuration);
    }

    /// @inheritdoc IGatedAirdrop
    /// @dev TODO when we have a more suitable Guild endpoint: remove guildIndex parameter
    function claim(uint256 guildIndex) external {
        if (block.timestamp > distributionEnd) revert DistributionEnded(block.timestamp, distributionEnd);
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (IERC20(token).balanceOf(address(this)) < amount) revert OutOfTokens();

        requestAccessCheck(
            msg.sender,
            guildIndex,
            rewardedRole,
            abi.encodeWithSelector(this.fulfillClaim.selector, msg.sender)
        );
    }

    /// @dev The actual claim function called by the oracle if the requirements are fulfilled.
    function fulfillClaim(address receiver) public onlyOracle {
        if (hasClaimed[receiver]) revert AlreadyClaimed();

        // Mark it claimed and send the token.
        hasClaimed[receiver] = true;
        if (!IERC20(token).transfer(receiver, amount)) revert TransferFailed(token, address(this), receiver);

        emit Claimed(receiver);
    }

    /// @inheritdoc IGatedAirdrop
    function prolongDistributionPeriod(uint128 additionalSeconds) external onlyOwner {
        uint128 newDistributionEnd = distributionEnd + additionalSeconds;
        distributionEnd = newDistributionEnd;
        emit DistributionProlonged(newDistributionEnd);
    }

    /// @inheritdoc IGatedAirdrop
    function withdraw(address recipient) external onlyOwner {
        if (block.timestamp <= distributionEnd) revert DistributionOngoing(block.timestamp, distributionEnd);
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert AlreadyWithdrawn();
        if (!IERC20(token).transfer(recipient, balance)) revert TransferFailed(token, address(this), recipient);
        emit Withdrawn(recipient, balance);
    }
}
