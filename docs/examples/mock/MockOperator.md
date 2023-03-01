# MockOperator

The Chainlink Mock Oracle contract.

Chainlink smart contract developers can use this to test their contracts.

Updated for Solidity ^0.8.0.

## Variables

### EXPIRY_TIME

```solidity
uint256 EXPIRY_TIME
```

### linkToken

```solidity
contract LinkTokenInterface linkToken
```

## Functions

### constructor

```solidity
constructor(
    address _link
) 
```

Deploy with the address of the LINK token.

Sets the linkToken address for the imported LinkTokenInterface.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_link` | address | The address of the LINK token. |

### oracleRequest

```solidity
function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256 _dataVersion,
    bytes _data
) external
```

Creates the Chainlink request.

Stores the hash of the params as the on-chain commitment for the request.
Emits OracleRequest event for the Chainlink node to detect.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_sender` | address | The sender of the request. |
| `_payment` | uint256 | The amount of payment given (specified in wei). |
| `_specId` | bytes32 | The Job Specification ID. |
| `_callbackAddress` | address | The callback address for the response |
| `_callbackFunctionId` | bytes4 | The callback function ID for the response. |
| `_nonce` | uint256 | The nonce sent by the requester. |
| `_dataVersion` | uint256 | The specified data version. |
| `_data` | bytes | The CBOR payload of the request. |

### fulfillOracleRequest

```solidity
function fulfillOracleRequest(
    bytes32 _requestId,
    bytes32 _data
) external returns (bool)
```

Called by the Chainlink node to fulfill requests.

Given params must hash back to the commitment stored from `oracleRequest`.
Will call the callback address's callback function without bubbling up error
checking in a `require` so that the node can get paid.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_requestId` | bytes32 | The fulfillment request ID that must match the requester's. |
| `_data` | bytes32 | The data to return to the consuming contract. |

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `[0]` | bool | Status if the external call was successful. |
### fulfillOracleRequest2

```solidity
function fulfillOracleRequest2(
    bytes32 _requestId,
    bytes _data
) external returns (bool)
```

Called by the Chainlink node to fulfill multiword requests.

Given params must hash back to the commitment stored from `oracleRequest`.
Will call the callback address's callback function without bubbling up error
checking in a `require` so that the node can get paid.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_requestId` | bytes32 | The fulfillment request ID that must match the requester's. |
| `_data` | bytes | The data to return to the consuming contract. |

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `[0]` | bool | Status if the external call was successful. |
### tryFulfillOracleRequest

```solidity
function tryFulfillOracleRequest(
    bytes32 _requestId,
    bytes32 _data
) external returns (bool)
```

Same as fulfillOracleRequest but bubbles up error data.

Useful for testing.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_requestId` | bytes32 | The fulfillment request ID that must match the requester's. |
| `_data` | bytes32 | The data to return to the consuming contract. |

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `[0]` | bool | Status if the external call was successful. |
### tryFulfillOracleRequest2

```solidity
function tryFulfillOracleRequest2(
    bytes32 _requestId,
    bytes _data
) external returns (bool)
```

Same as fulfillOracleRequest2 but bubbles up error data.

Useful for testing.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_requestId` | bytes32 | The fulfillment request ID that must match the requester's. |
| `_data` | bytes | The data to return to the consuming contract. |

#### Return Values

| Name | Type | Description |
| :--- | :--- | :---------- |
| `[0]` | bool | Status if the external call was successful. |
### cancelOracleRequest

```solidity
function cancelOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 ,
    uint256 _expiration
) external
```

Allows requesters to cancel requests sent to this oracle contract. Will transfer the LINK
sent for the request back to the requester's address.

Given params must hash to a commitment stored on the contract in order for the request to be valid
Emits CancelOracleRequest event.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `_requestId` | bytes32 | The request ID. |
| `_payment` | uint256 | The amount of payment given (specified in wei). |
| `` | bytes4 |  |
| `_expiration` | uint256 | The time of the expiration for the request. |

### onTokenTransfer

```solidity
function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes data
) public
```

Called when LINK is sent to the contract via `transferAndCall`

The data payload's first 2 words will be overwritten by the `sender` and `amount`
values to ensure correctness. Calls oracleRequest.
Taken from LinkTokenReceiver.sol.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `sender` | address | Address of the sender. |
| `amount` | uint256 | Amount of LINK sent (specified in wei). |
| `data` | bytes | Payload of the transaction. |

### getChainlinkToken

```solidity
function getChainlinkToken() public returns (address)
```

Returns the address of the LINK token.

This is the public implementation for chainlinkTokenAddress, which is
an internal method of the ChainlinkClient contract.

### handleRevert

```solidity
function handleRevert(
    bytes returndata
) internal
```

Get the revert reason or custom error from a bytes array and revert with it.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `returndata` | bytes |  |

## Modifiers

### isValidRequest

```solidity
modifier isValidRequest(bytes32 _requestId)
```

_Reverts if request ID does not exist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _requestId | bytes32 | The given request ID to check in stored `commitments`. |

### checkCallbackAddress

```solidity
modifier checkCallbackAddress(address _to)
```

_Reverts if the callback address is the LINK token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | The callback address. |

### validateFromLINK

```solidity
modifier validateFromLINK()
```

_Reverts if not sent from the LINK token.
Taken from LinkTokenReceiver.sol._

### validateMultiWordResponseId

```solidity
modifier validateMultiWordResponseId(bytes32 requestId, bytes data)
```

_Reverts if the first 32 bytes of the bytes array is not equal to requestId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requestId | bytes32 | bytes32 |
| data | bytes | bytes |

## Events

### OracleRequest

```solidity
event OracleRequest(
    bytes32 specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
)
```

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `specId` | bytes32 |  |
| `requester` | address |  |
| `requestId` | bytes32 |  |
| `payment` | uint256 |  |
| `callbackAddr` | address |  |
| `callbackFunctionId` | bytes4 |  |
| `cancelExpiration` | uint256 |  |
| `dataVersion` | uint256 |  |
| `data` | bytes |  |
### CancelOracleRequest

```solidity
event CancelOracleRequest(
    bytes32 requestId
)
```

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `requestId` | bytes32 |  |

## Custom types

### Request

```solidity
struct Request {
  address callbackAddr;
  bytes4 callbackFunctionId;
}
```

