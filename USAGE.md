# Usage Instructions For Developers

## i.e. "how to Guild-gate my contracts"

### The base contract

First, you'll need the [RequestGuildRole](contracts/RequestGuildRole.sol) abstract contract. Copy it to your project and leave it as it is.

### Your feature contract

You can Guild-gate any of the functions in your own contract in a few simple steps:

1. Import the RequestGuildRole contract:

   <!-- prettier-ignore -->
   ```solidity
   import { RequestGuildRole } from "./RequestGuildRole.sol";
   ```

2. Make your contract inherit from the RequestGuildRole contract:

   <!-- prettier-ignore -->
   ```solidity
   contract YourContract is RequestGuildRole /*, etc.*/ {
       /*...*/
   }
   ```

3. Call the super contract's constructor. It will need 5 additional parameters, too.

   <!-- prettier-ignore -->
   ```solidity
   constructor(
       /* your arguments */
       string memory guildId,
       address linkToken,
       address oracleAddress,
       bytes32 jobId,
       uint256 oracleFee
   ) RequestGuildRole(linkToken, oracleAddress, jobId, oracleFee, guildId) {
       /*...*/
   }
   ```

   For more info on what these are, refer to the [docs](docs/RequestGuildRole.md#constructor).  
   For the LINK token's address on different chains check [this page](https://docs.chain.link/docs/link-token-contracts).  
   Guide to find a suitable oracle job [here](https://docs.chain.link/docs/listing-services/#find-a-job).

4. You'll probably want to store the id of the role you want to gate with. It's a `uint96` for gas optimization reasons.  
   To get the id of your preferred role, you can use the following enpoint: `https://api.guild.xyz/v1/guild/[your-guild-id]`, where _[your-guild-id]_ is the id of your Guild.  
   To get the id of your Guild, one approach is to use the membership endpoint: `https://api.guild.xyz/v1/user/membership/[your-address]`, where _[your-address]_ is your public address that you use with Guild. If you are a member of the guild you are trying to gate with, one of the ids will be the one you are looking for.

5. Split the logic of the function you want to gate:

   - the user-facing function should contain only some checks, the request to the oracle and possibly emit an event. The oracle request should be a call to the [requestAccessCheck](docs/RequestGuildRole.md#requestaccesscheck) function.  
     Note: any parameters you wish to pass to the function that will be called by the oracle should be included in the `args` parameter in an abi encoded form, e.g.: `abi.encode(var1, var2)`
   - the function called by the oracle with the response should only have two arguments: `bytes32 requestId`, `uint256 access`. It also has to have the [checkRole](docs/RequestGuildRole.md#checkrole) modifier.  
     Note: the function's parameters cannot be extended, however, you can use the args parameter passed to the requestAccessCheck function in the previous step, you just have to [abi decode](https://docs.soliditylang.org/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions) them from `requests[requestId].args`. Example with an address and a uint256 argument:
     ```solidity
     (address var1, uint256 var2) = abi.decode(requests[requestId].args, (address, uint256));
     ```

### After deployment

Be sure to fund your contract with LINK tokens. The oracle will not respond if it's not getting paid.

### Examples

Check out the already available Guild-gated example contracts in this project for further inspiration.
