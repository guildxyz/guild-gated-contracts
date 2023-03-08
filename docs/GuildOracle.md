# GuildOracle

Guild Oracle.

Base contract to check an address's accesses, roles, admin/owner status on Guild.xyz via a Chainlink oracle.

Inherit from this contract to have easy access to Guild's access check.

## Variables

### requests

```solidity
mapping(bytes32 => struct GuildOracle.RequestParams) requests
```

The request parameters mapped to the requestIds.

### oracleFee

```solidity
uint256 oracleFee
```

The amount of tokens to forward to the oracle with every request.

### jobId

```solidity
bytes32 jobId
```

The id of the job to run on the oracle.

## Functions

### constructor

```solidity
constructor(
    address linkToken,
    address oracleAddress,
    bytes32 jobId_,
    uint256 oracleFee_
) 
```

Sets the oracle's details.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `linkToken` | address | The address of the Chainlink token. |
| `oracleAddress` | address | The address of the oracle processing the requests. |
| `jobId_` | bytes32 | The id of the job to run on the oracle. |
| `oracleFee_` | uint256 | The amount of tokens to forward to the oracle with every request. |

### requestGuildRoleAccessCheck

```solidity
function requestGuildRoleAccessCheck(
    address addressToCheck,
    uint256 roleId,
    uint256 guildId,
    bytes4 callbackFn,
    bytes args
) internal
```

Sends a request to the oracle querying if the user has access to a certain role on Guild.

The user may not actually hold the role.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `addressToCheck` | address | The address of the user. |
| `roleId` | uint256 | The roleId that has to be checked. |
| `guildId` | uint256 | The id of the guild the rewarded role is in. |
| `callbackFn` | bytes4 | The identifier of the function the oracle should call when fulfilling the request. |
| `args` | bytes | Any additional function arguments in an abi encoded form. |

### requestGuildRoleCheck

```solidity
function requestGuildRoleCheck(
    address addressToCheck,
    uint256 roleId,
    bytes4 callbackFn,
    bytes args
) internal
```

Sends a request to the oracle querying if the user has obtained a certain role on Guild.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `addressToCheck` | address | The address of the user. |
| `roleId` | uint256 | The id of the role that needs to be checked. |
| `callbackFn` | bytes4 | The identifier of the function the oracle should call when fulfilling the request. |
| `args` | bytes | Any additional function arguments in an abi encoded form. |

### requestGuildJoinCheck

```solidity
function requestGuildJoinCheck(
    address addressToCheck,
    uint256 guildId,
    bytes4 callbackFn,
    bytes args
) internal
```

Sends a request to the oracle querying if the user has joined a certain guild.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `addressToCheck` | address | The address of the user. |
| `guildId` | uint256 | The id of the guild that needs to be checked. |
| `callbackFn` | bytes4 | The identifier of the function the oracle should call when fulfilling the request. |
| `args` | bytes | Any additional function arguments in an abi encoded form. |

### requestGuildAdminCheck

```solidity
function requestGuildAdminCheck(
    address addressToCheck,
    uint256 guildId,
    bytes4 callbackFn,
    bytes args
) internal
```

Sends a request to the oracle querying if the user is an admin of a certain guild.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `addressToCheck` | address | The address of the user. |
| `guildId` | uint256 | The id of the guild that needs to be checked. |
| `callbackFn` | bytes4 | The identifier of the function the oracle should call when fulfilling the request. |
| `args` | bytes | Any additional function arguments in an abi encoded form. |

### requestGuildOwnerCheck

```solidity
function requestGuildOwnerCheck(
    address addressToCheck,
    uint256 guildId,
    bytes4 callbackFn,
    bytes args
) internal
```

Sends a request to the oracle querying if the user is the owner of a certain guild.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `addressToCheck` | address | The address of the user. |
| `guildId` | uint256 | The id of the guild that needs to be checked. |
| `callbackFn` | bytes4 | The identifier of the function the oracle should call when fulfilling the request. |
| `args` | bytes | Any additional function arguments in an abi encoded form. |

## Modifiers

### checkResponse

```solidity
modifier checkResponse(bytes32 requestId, uint256 access)
```

Processes the data returned by the Chainlink node.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requestId | bytes32 | The id of the request. |
| access | uint256 | The value returned by the oracle. |

## Events

### HasAccess

```solidity
event HasAccess(
    address userAddress
)
```

Event emitted when an address is successfully verified to have a role.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `userAddress` | address | The address of the queried user. |

## Custom errors

### NoAccess

```solidity
error NoAccess(address userAddress)
```

Error thrown when an address doesn't have the needed role.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| userAddress | address | The address of the queried user. |

### AccessCheckFailed

```solidity
error AccessCheckFailed(address userAddress)
```

Error thrown when a role check failed due to an unavailable server or invalid return data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| userAddress | address | The address of the queried user. |

## Custom types

### Access

```solidity
enum Access {
  NO_ACCESS,
  ACCESS,
  CHECK_FAILED
}
```
### RequestParams

```solidity
struct RequestParams {
  address userAddress;
  bytes args;
}
```

