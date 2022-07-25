import { ethers } from "hardhat";

const token = "0x..."; // The address of the token to distribute.
const amount = ethers.utils.parseEther("1"); // The amount of tokens each address can claim.
const distributionDuration = 86400; // The length of the distribution period in seconds.

async function main() {
  const GatedAirdrop = await ethers.getContractFactory("GatedAirdrop");
  const airdrop = await GatedAirdrop.deploy(token, amount, distributionDuration);

  await airdrop.deployed();

  console.log("Contract deployed to:", airdrop.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
