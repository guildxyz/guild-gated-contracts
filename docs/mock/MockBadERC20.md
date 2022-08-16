# MockBadERC20

An ERC20 token that returns false on transfer.

Use only for tests.

## Functions

### constructor

```solidity
constructor() 
```

### transfer

```solidity
function transfer(
    address to,
    uint256 amount
) public returns (bool)
```

Same as the regular transfer, but returns false.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `to` | address |  |
| `amount` | uint256 |  |

### transferFrom

```solidity
function transferFrom(
    address from,
    address to,
    uint256 amount
) public returns (bool)
```

Same as the regular transferFrom, but returns false.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `from` | address |  |
| `to` | address |  |
| `amount` | uint256 |  |

