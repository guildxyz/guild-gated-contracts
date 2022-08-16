# GatedDistributor

A Guild-gated ERC20 distributor.

## Variables

### rewardedRole

```solidity
uint96 rewardedRole
```

Returns the id of the role in Guild.

### rewardToken

```solidity
address rewardToken
```

Returns the address of the token distributed by this contract.

### rewardAmount

```solidity
uint128 rewardAmount
```

Returns the amount of tokens an eligible address can claim.

### distributionEnd

```solidity
uint128 distributionEnd
```

Returns the unix timestamp that marks the end of the token distribution.

### hasClaimed

```solidity
mapping(address => bool) hasClaimed
```

Returns true if the address has already claimed their tokens.

## Functions

### constructor

```solidity
constructor(
    address token_,
    uint128 amount_,
    uint256 distributionDuration,
    string guildId,
    uint96 rewardedRole_,
    address linkToken,
    address oracleAddress,
    bytes32 jobId,
    uint256 oracleFee
) 
```

Sets the config and the oracle details.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `token_` | address | The address of the ERC20 token to distribute. |
| `amount_` | uint128 | The amount of tokens an eligible address will be able to claim. |
| `distributionDuration` | uint256 | The time interval while the distribution lasts in seconds. |
| `guildId` | string | The id of the guild the rewarded role is in. |
| `rewardedRole_` | uint96 | The id of the rewarded role on Guild. |
| `linkToken` | address | The address of the Chainlink token. |
| `oracleAddress` | address | The address of the oracle processing the requests. |
| `jobId` | bytes32 | The id of the job to run on the oracle. |
| `oracleFee` | uint256 | The amount of tokens to forward to the oracle with every request. |

### claim

```solidity
function claim() external
```

Claims the given amount of the token to the given address. Reverts if the inputs are invalid.

### fulfillClaim

```solidity
function fulfillClaim(
    bytes32 requestId,
    uint256 access
) public
```

The actual claim function called by the oracle if the requirements are fulfilled.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `requestId` | bytes32 |  |
| `access` | uint256 |  |

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

