# IGatedDistributor

Provides ERC20 token distribution based on fulfilling specific criteria on guild.xyz.

## Functions

### guildId

```solidity
function guildId() external returns (uint256 guild)
```

Returns the id of the guild the rewarded role(s) is/are in.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `guild` | uint256 | The id of the guild. |
### rewardedRole

```solidity
function rewardedRole() external returns (uint256 role)
```

Returns the id of the role in Guild.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `role` | uint256 | The id of the role. |
### rewardToken

```solidity
function rewardToken() external returns (address tokenAddress)
```

Returns the address of the token distributed by this contract.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `tokenAddress` | address | The address of the token. |
### rewardAmount

```solidity
function rewardAmount() external returns (uint128 tokenAmount)
```

Returns the amount of tokens an eligible address can claim.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `tokenAmount` | uint128 | The amount in wei. |
### distributionEnd

```solidity
function distributionEnd() external returns (uint128 unixSeconds)
```

Returns the unix timestamp that marks the end of the token distribution.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `unixSeconds` | uint128 | The unix timestamp in seconds. |
### hasClaimed

```solidity
function hasClaimed(
    address account,
    enum IGatedDistributor.GuildAction guildAction
) external returns (bool claimed)
```

Returns true if the address has already claimed their tokens.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `account` | address | The user's address. |
| `guildAction` | enum IGatedDistributor.GuildAction | The action which has been checked via the oracle. |

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `claimed` | bool | Whether the address has claimed their tokens. |
### claim

```solidity
function claim(
    enum IGatedDistributor.GuildAction guildAction
) external
```

Claims the given amount of the token to the given address. Reverts if the inputs are invalid.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `guildAction` | enum IGatedDistributor.GuildAction | The action to check via the oracle. |

### prolongDistributionPeriod

```solidity
function prolongDistributionPeriod(
    uint128 additionalSeconds
) external
```

Prolongs the distribution period of the tokens. Callable only by the owner.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `additionalSeconds` | uint128 | The seconds to add to the current distributionEnd. |

### withdraw

```solidity
function withdraw(
    address recipient
) external
```

Sends the tokens remaining after the distribution has ended to `recipient`. Callable only by the owner.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `recipient` | address | The address receiving the tokens. |

## Events

### Claimed

```solidity
event Claimed(
    address receiver,
    enum IGatedDistributor.GuildAction guildAction
)
```

Event emitted whenever a claim succeeds (is fulfilled).

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `receiver` | address | The address that received the tokens. |
| `guildAction` | enum IGatedDistributor.GuildAction | The action to check via the oracle. |
### ClaimRequested

```solidity
event ClaimRequested(
    address receiver,
    enum IGatedDistributor.GuildAction guildAction
)
```

Event emitted whenever a claim is requested.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `receiver` | address | The address that receives the tokens. |
| `guildAction` | enum IGatedDistributor.GuildAction | The action that has been checked via the oracle. |
### DistributionProlonged

```solidity
event DistributionProlonged(
    uint128 newDistributionEnd
)
```

Event emitted whenever a call to {prolongDistributionPeriod} succeeds.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `newDistributionEnd` | uint128 | The time when the distribution ends. |
### Withdrawn

```solidity
event Withdrawn(
    address account,
    uint256 amount
)
```

Event emitted whenever a call to {withdraw} succeeds.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `account` | address | The address that received the tokens. |
| `amount` | uint256 | The amount of tokens the address received. |

## Custom errors

### AlreadyWithdrawn

```solidity
error AlreadyWithdrawn()
```

Error thrown when there's nothing to withdraw.

### DistributionEnded

```solidity
error DistributionEnded(uint256 current, uint256 end)
```

Error thrown when the distribution period ended.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| current | uint256 | The current timestamp. |
| end | uint256 | The time when the distribution ended. |

### DistributionOngoing

```solidity
error DistributionOngoing(uint256 current, uint256 end)
```

Error thrown when the distribution period did not end yet.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| current | uint256 | The current timestamp. |
| end | uint256 | The time when the distribution ends. |

### AlreadyClaimed

```solidity
error AlreadyClaimed()
```

Error thrown when the drop is already claimed.

### InvalidParameters

```solidity
error InvalidParameters()
```

Error thrown when a function receives invalid parameters.

### InvalidProof

```solidity
error InvalidProof()
```

Error thrown when the Merkle proof is invalid.

### OutOfTokens

```solidity
error OutOfTokens()
```

Error thrown when the contract has less tokens than needed for a claim.

### TransferFailed

```solidity
error TransferFailed(address token, address from, address to)
```

Error thrown when a transfer failed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The address of token attempted to be transferred. |
| from | address | The sender of the token. |
| to | address | The recipient of the token. |

## Custom types

### GuildAction

```solidity
enum GuildAction {
  HAS_ACCESS,
  HAS_ROLE,
  IS_ADMIN,
  IS_OWNER,
  JOINED_GUILD
}
```

