import { ethers } from "hardhat";

// AIRDROP CONFIG
const token = "0x..."; // The address of the token to distribute.
const amount = ethers.utils.parseEther("1"); // The amount of tokens each address can claim.
const distributionDuration = 86400; // The length of the distribution period in seconds.
const guildId = "1985"; // The id of the guild the rewarded role is in. (default: Our Guild)
const rewardedRole = "1904"; // The role that will be able to claim rewards. (default: Guild Member)

// ORACLE CONFIG (default: Rinkeby)
const chainlinkToken = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709";
const oracleAddress = "0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434";
const jobId = "0x7599d3c8f31e4ce78ad2b790cbcfc673".padEnd(66, "0");
const oracleFee = ethers.BigNumber.from("50000000000000000");

async function main() {
  const GatedDistributor = await ethers.getContractFactory("GatedDistributor");
  const distributor = await GatedDistributor.deploy(
    token,
    amount,
    distributionDuration,
    guildId,
    rewardedRole,
    chainlinkToken,
    oracleAddress,
    jobId,
    oracleFee
  );

  console.log(
    `Deploying contract to ${
      ethers.provider.network.name !== "unknown" ? ethers.provider.network.name : ethers.provider.network.chainId
    }...`
  );

  await distributor.deployed();

  console.log("Gated Distributor contract deployed to:", distributor.address);
  console.log(
    "Constructor arguments:",
    token,
    amount.toString(),
    distributionDuration.toString(),
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
