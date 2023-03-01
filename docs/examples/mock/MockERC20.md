# MockERC20

A mintable and burnable ERC20 token.

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

### mint

```solidity
function mint(
    address account,
    uint256 amount
) external
```

Mint `amount` of tokens to `account`.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `account` | address | The address of the account receiving the tokens. |
| `amount` | uint256 | The amount of tokens the account receives. |

### burn

```solidity
function burn(
    address account,
    uint256 amount
) external
```

Burn `amount` of tokens from `account`.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `account` | address | The address of the account to burn tokens from. |
| `amount` | uint256 | The amount of tokens to burn in wei. |

