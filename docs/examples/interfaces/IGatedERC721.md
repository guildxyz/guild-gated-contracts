# IGatedERC721

An ERC721 token that can be claimed only by those holding a specific role on guild.xyz.

## Functions

### hasClaimed

```solidity
function hasClaimed(
    address account
) external returns (bool claimed)
```

Returns true if the address has already claimed their token.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `account` | address | The user's address. |

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `claimed` | bool | Whether the address has claimed their token. |
### maxSupply

```solidity
function maxSupply() external returns (uint256 count)
```

The maximum number of NFTs that can ever be minted.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `count` | uint256 | The number of NFTs. |
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
### totalSupply

```solidity
function totalSupply() external returns (uint256 count)
```

The total amount of tokens stored by the contract.

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `count` | uint256 | The number of NFTs. |
### claim

```solidity
function claim(
    enum IGatedERC721.GuildAction guildAction
) external
```

Claims tokens to the given address.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `guildAction` | enum IGatedERC721.GuildAction | The action to check via the oracle. |

## Events

### Claimed

```solidity
event Claimed(
    address receiver,
    enum IGatedERC721.GuildAction guildAction
)
```

Event emitted whenever a claim succeeds (is fulfilled).

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `receiver` | address | The address that received the tokens. |
| `guildAction` | enum IGatedERC721.GuildAction | The action to check via the oracle. |
### ClaimRequested

```solidity
event ClaimRequested(
    address receiver,
    enum IGatedERC721.GuildAction guildAction
)
```

Event emitted whenever a claim is requested.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `receiver` | address | The address that receives the tokens. |
| `guildAction` | enum IGatedERC721.GuildAction | The action that has been checked via the oracle. |

## Custom errors

### AlreadyClaimed

```solidity
error AlreadyClaimed()
```

Error thrown when the token is already claimed.

### MaxSupplyZero

```solidity
error MaxSupplyZero()
```

Error thrown when the maximum supply attempted to be set is zero.

### NonExistentToken

```solidity
error NonExistentToken(uint256 tokenId)
```

Error thrown when trying to query info about a token that's not (yet) minted.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The queried id. |

### TokenIdOutOfBounds

```solidity
error TokenIdOutOfBounds(uint256 tokenId, uint256 maxSupply)
```

Error thrown when the tokenId is higher than the maximum supply.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id that was attempted to be used. |
| maxSupply | uint256 | The maximum supply of the token. |

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

