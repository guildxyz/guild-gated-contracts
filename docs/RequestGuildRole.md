# RequestGuildRole

Guild.xyz role checker.

Base contract to check an address's roles on Guild.xyz via a Chainlink oracle.

Inherit from this contract to have easy access to Guild's access check.

## Variables

### requests

```solidity
mapping(bytes32 => struct RequestGuildRole.RequestParams) requests
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

### guildId

```solidity
string guildId
```

The id of the guild the rewarded role(s) is/are in.

## Functions

### constructor

```solidity
constructor(
    address linkToken,
    address oracleAddress,
    bytes32 jobId_,
    uint256 oracleFee_,
    string guildId_
) 
```

Sets the oracle's details and the guild where the roles are in.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `linkToken` | address | The address of the Chainlink token. |
| `oracleAddress` | address | The address of the oracle processing the requests. |
| `jobId_` | bytes32 | The id of the job to run on the oracle. |
| `oracleFee_` | uint256 | The amount of tokens to forward to the oracle with every request. |
| `guildId_` | string | The id of the guild the queried role(s) is/are in. |

### requestAccessCheck

```solidity
function requestAccessCheck(
    address userAddress,
    uint96 roleId,
    bytes4 callbackFn,
    bytes args
) internal
```

Requests the needed data from the oracle.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `userAddress` | address | The address of the user. |
| `roleId` | uint96 | The roleId that has to be checked. |
| `callbackFn` | bytes4 | The identifier of the function the oracle should call when fulfulling the request. |
| `args` | bytes | Any additional function arguments in an abi encoded form. |

## Modifiers

### checkRole

```solidity
modifier checkRole(bytes32 requestId, uint256 access)
```

Processes the data returned by the Chainlink node.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requestId | bytes32 | The id of the request. |
| access | uint256 | The value returned by the oracle. |

## Events

### HasRole

```solidity
event HasRole(
    address userAddress,
    uint96 roleId
)
```

Event emitted when an address is successfully verified to have a role.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `userAddress` | address | The address of the queried user. |
| `roleId` | uint96 | The id of the queried role. |

## Custom errors

### NoRole

```solidity
error NoRole(address userAddress, uint96 roleId)
```

Error thrown when an address doesn't have the needed role.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| userAddress | address | The address of the queried user. |
| roleId | uint96 | The id of the queried role. |

### CheckingRoleFailed

```solidity
error CheckingRoleFailed(address userAddress, uint96 roleId)
```

Error thrown when a role check failed due to an unavailable server or invalid return data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| userAddress | address | The address of the queried user. |
| roleId | uint96 | The id of the queried role. |

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
  uint96 roleId;
  bytes args;
}
```

