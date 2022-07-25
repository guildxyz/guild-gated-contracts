//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IGatedAirdrop } from "./interfaces/IGatedAirdrop.sol";
import { RequestGuildRole } from "./RequestGuildRole.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A Guild-gated ERC20 airdrop.
contract GatedAirdrop is IGatedAirdrop, RequestGuildRole, Ownable {
    uint256 public constant GUILD_MEMBER_ROLEID = 1904; // Guild Member

    /// @inheritdoc IGatedAirdrop
    address public immutable token;
    /// @inheritdoc IGatedAirdrop
    uint256 public immutable amount;
    /// @inheritdoc IGatedAirdrop
    uint256 public distributionEnd;

    /// @inheritdoc IGatedAirdrop
    mapping(address => bool) public hasClaimed;

    /// @notice Sets config and the oracle details.
    /// @param token_ The address of the ERC20 token to distribute.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    constructor(
        address token_,
        uint256 amount_,
        uint256 distributionDuration
    ) RequestGuildRole() {
        if (token_ == address(0)) revert InvalidParameters();

        token = token_;
        amount = amount_;
        distributionEnd = block.timestamp + distributionDuration;
    }

    /// @notice Checks if the sender is the oracle address.
    modifier onlyOracle() {
        if (msg.sender != chainlinkOracleAddress()) revert OnlyOracle();
        _;
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
            GUILD_MEMBER_ROLEID,
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
    function prolongDistributionPeriod(uint256 additionalSeconds) external onlyOwner {
        uint256 newDistributionEnd = distributionEnd + additionalSeconds;
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
