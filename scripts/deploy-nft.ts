import { ethers } from "hardhat";

// NFT METADATA
const name = ""; // The name of the token.
const symbol = ""; // The short, usually all caps symbol of the token.
const cid = ""; // The ipfs hash, under which the off-chain metadata is uploaded.
const maxSupply = 500; // The maximum amount of tokens that can ever get minted.

// AIRDROP CONFIG
const guildId = "1985"; // The id of the guild the rewarded role is in. (default: Our Guild)
const rewardedRole = "1904"; // The role that will be able to claim rewards. (default: Guild Member)

// ORACLE CONFIG (default: Rinkeby)
const chainlinkToken = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709";
const oracleAddress = "0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434";
const jobId = "0x7599d3c8f31e4ce78ad2b790cbcfc673".padEnd(66, "0");
const oracleFee = ethers.BigNumber.from("50000000000000000");

async function main() {
  const GatedERC721 = await ethers.getContractFactory("GatedERC721");

  console.log(
    `Deploying contract to ${
      ethers.provider.network.name !== "unknown" ? ethers.provider.network.name : ethers.provider.network.chainId
    }...`
  );

  const nft = await GatedERC721.deploy(
    name,
    symbol,
    cid,
    maxSupply,
    guildId,
    rewardedRole,
    chainlinkToken,
    oracleAddress,
    jobId,
    oracleFee
  );
  await nft.deployed();

  console.log("Gated ERC721 contract deployed to:", nft.address);
  console.log(
    "Constructor arguments:",
    name,
    symbol,
    cid,
    maxSupply,
    guildId,
    rewardedRole,
    chainlinkToken,
    oracleAddress,
    jobId,
    oracleFee.toString()
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
