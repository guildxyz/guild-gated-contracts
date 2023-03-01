# GatedERC721

An ERC721 token that can be claimed only by those holding a specific role on guild.xyz.

## Variables

### rewardedRole

```solidity
uint96 rewardedRole
```

Returns the id of the role in Guild.

### maxSupply

```solidity
uint256 maxSupply
```

The maximum number of NFTs that can ever be minted.

### totalSupply

```solidity
uint256 totalSupply
```

The total amount of tokens stored by the contract.

### cid

```solidity
string cid
```

The ipfs hash, under which the off-chain metadata is uploaded.

### hasClaimed

```solidity
mapping(address => bool) hasClaimed
```

Returns true if the address has already claimed their token.

## Functions

### constructor

```solidity
constructor(
    string name,
    string symbol,
    string cid_,
    uint256 maxSupply_,
    string guildId,
    uint96 rewardedRole_,
    address linkToken,
    address oracleAddress,
    bytes32 jobId,
    uint256 oracleFee
) 
```

Sets metadata and the oracle details.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `name` | string | The name of the token. |
| `symbol` | string | The symbol of the token. |
| `cid_` | string | The ipfs hash, under which the off-chain metadata is uploaded. |
| `maxSupply_` | uint256 | The maximum number of NFTs that can ever be minted. |
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

Claims tokens to the given address.

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

### _safeMint

```solidity
function _safeMint(
    address to,
    uint256 tokenId
) internal
```

An optimized version of {_safeMint} using custom errors.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `to` | address |  |
| `tokenId` | uint256 |  |

### tokenURI

```solidity
function tokenURI(
    uint256 tokenId
) public returns (string)
```

Returns the Uniform Resource Identifier (URI) for `tokenId` token.

#### Parameters

| Name | Type | Description |
| :--- | :--- | :---------- |
| `tokenId` | uint256 | The id of the token. |

