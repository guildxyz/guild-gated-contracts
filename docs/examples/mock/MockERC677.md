# ERC677Receiver

The interface of an ERC677 Receiver contract.

## Functions

### onTokenTransfer

```solidity
function onTokenTransfer(
    address sender,
    uint256 value,
    bytes data
) external
```

Hook called on token transfers.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `sender` | address | The sender of the tokens. |
| `value` | uint256 | The amount to be transferred. |
| `data` | bytes | The extra data to be passed to the receiving contract. |

# MockERC677

A mintable and burnable ERC677 token.

Use only for tests.

## Functions

### constructor

```solidity
constructor(
    string name,
    string symbol
) 
```

Sets metadata.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `name` | string | The name of the token. |
| `symbol` | string | The symbol of the token. |

### transferAndCall

```solidity
function transferAndCall(
    address to,
    uint256 value,
    bytes data
) public returns (bool success)
```

Transfer token to a contract address with additional data if the recipient is a contract.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `to` | address | The address to transfer to. |
| `value` | uint256 | The amount to be transferred. |
| `data` | bytes | The extra data to be passed to the receiving contract. |

