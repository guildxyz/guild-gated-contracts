import { ethers } from "hardhat";

// AIRDROP CONFIG
const token = "0x..."; // The address of the token to distribute.
const amount = ethers.utils.parseEther("1"); // The amount of tokens each address can claim.
const distributionDuration = 86400; // The length of the distribution period in seconds.
const rewardedRole = 1904; // The role that will be able to claim rewards. (default: Guild Member)

// ORACLE CONFIG (default: Rinkeby)
const chainlinkToken = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709";
const oracleAddress = "0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434";
const jobId = ethers.utils.hexZeroPad("0xa56c23c069b446a5bfd3b5fc91383991", 32);
const oracleFee = ethers.BigNumber.from("50000000000000000");

async function main() {
  const GatedAirdrop = await ethers.getContractFactory("GatedAirdrop");
  const airdrop = await GatedAirdrop.deploy(
    token,
    amount,
    distributionDuration,
    rewardedRole,
    chainlinkToken,
    oracleAddress,
    jobId,
    oracleFee
  );

  await airdrop.deployed();

  console.log("Contract deployed to:", airdrop.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
