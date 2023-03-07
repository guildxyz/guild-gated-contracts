import { expect } from "chai";
import { ethers } from "hardhat";
import type { Contract, ContractTransaction } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

async function getRequestId(tx: ContractTransaction): Promise<string> {
  const res = await tx.wait();
  // Assuming the first event's name is ChainlinkRequested
  expect(res.logs[0].topics[0]).to.eq("0xb5e6e01e79f91267dc17b4e6314d5d4d03593d2ceee0fbb452b750bd70ea5af9");
  // The first indexed parameter of ChainlinkRequested is the requestId
  return res.logs[0].topics[1]; // eslint-disable-line prefer-destructuring
}

let token: Contract;

const tokenName = "OwoNFT";
const tokenSymbol = "OFT";
const tokenCid = "QmPaZD7i8TpLEeGjHtGoXe4mPKbRNNt8YTHH5nrKoqz9wJ";
const tokenMaxSupply = "12";
const guildId = "1985";
const rewardedRole = "1904";
let chainlinkToken: Contract;
let chainlinkOperator: Contract;
const jobId = "0xf7f77ea15719ea30bd2a584962ab273b1116f0e70fe80bbb0b30557d0addb7f3";
const oracleFee = 0;

let wallet0: SignerWithAddress;
let wallet1: SignerWithAddress;

const oracleResponse = {
  NO_ACCESS: "0x".padEnd(66, "0"),
  ACCESS: `${"0x".padEnd(65, "0")}1`,
  CHECK_FAILED: `${"0x".padEnd(65, "0")}2`
};

describe("GatedERC721", function () {
  this.beforeAll("deploy oracle", async () => {
    [wallet0, wallet1] = await ethers.getSigners();

    const LINK = await ethers.getContractFactory("MockERC677");
    const submittedLinkToken = await LINK.deploy("Link Token", "LINK");

    chainlinkToken = await submittedLinkToken.deployed();

    const Operator = await ethers.getContractFactory("MockOperator");
    const submittedOperator = await Operator.deploy(chainlinkToken.address);
    chainlinkOperator = await submittedOperator.deployed();
  });

  this.beforeEach("deploy nft", async () => {
    const GatedERC721 = await ethers.getContractFactory("GatedERC721");
    token = await GatedERC721.deploy(
      tokenName,
      tokenSymbol,
      tokenCid,
      tokenMaxSupply,
      guildId,
      rewardedRole,
      chainlinkToken.address,
      chainlinkOperator.address,
      jobId,
      oracleFee
    );
    await token.deployed();
  });

  context("#constructor", () => {
    it("fails if maxSupply is 0", async () => {
      const GatedERC721 = await ethers.getContractFactory("GatedERC721");
      await expect(
        GatedERC721.deploy(
          tokenName,
          tokenSymbol,
          tokenCid,
          0,
          guildId,
          rewardedRole,
          chainlinkToken.address,
          chainlinkOperator.address,
          jobId,
          oracleFee
        )
      ).to.revertedWithCustomError(token, "MaxSupplyZero");
    });

    it("should initialize state variables", async () => {
      const name = await token.name();
      const symbol = await token.symbol();
      const maxSupply = await token.maxSupply();
      const role = await token.rewardedRole();
      const owner = await token.owner();
      expect(name).to.eq(tokenName);
      expect(symbol).to.eq(tokenSymbol);
      expect(maxSupply).to.eq(tokenMaxSupply);
      expect(role).to.eq(rewardedRole);
      expect(owner).to.eq(wallet0.address);
    });

    it("should have zero tokens initially", async () => {
      const totalSupply = await token.totalSupply();
      expect(totalSupply).to.eq(0);
    });
  });

  context("#tokenURI", () => {
    it("should revert when trying to get the tokenURI for a non-existent token", async () => {
      await expect(token.tokenURI(84)).to.revertedWithCustomError(token, "NonExistentToken").withArgs(84);
    });

    it("should return the correct tokenURI", async () => {
      const requestId = await getRequestId(await token.claim(0));
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      const regex = new RegExp(`ipfs://${tokenCid}/0.json`);
      expect(regex.test(await token.tokenURI(0))).to.eq(true);
    });
  });

  context("#claim", () => {
    it("fails if the address has already claimed", async () => {
      const requestId = await getRequestId(await token.claim(0));
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      await expect(token.claim(0)).to.be.revertedWithCustomError(token, "AlreadyClaimed");
    });

    it("fails if all the tokens are already minted", async () => {
      const GatedERC721 = await ethers.getContractFactory("GatedERC721");
      token = await GatedERC721.deploy(
        tokenName,
        tokenSymbol,
        tokenCid,
        1,
        guildId,
        rewardedRole,
        chainlinkToken.address,
        chainlinkOperator.address,
        jobId,
        oracleFee
      );
      await token.deployed();

      const requestId = await getRequestId(await token.claim(0));
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);

      const maxSupply = await token.maxSupply();
      expect(await token.totalSupply()).to.eq(maxSupply);
      await expect(token.connect(wallet1).claim(0))
        .to.be.revertedWithCustomError(token, "TokenIdOutOfBounds")
        .withArgs(1, maxSupply);
    });

    it("should successfully make claim requests", async () => {
      const tx0 = await token.claim(0);
      const res0 = await tx0.wait();
      expect(res0.status).to.equal(1);
      const tx1 = await token.connect(wallet1).claim(0);
      const res1 = await tx1.wait();
      expect(res1.status).to.equal(1);
    });

    it("emits ClaimRequested event", async () => {
      await expect(token.claim(0)).to.emit(token, "ClaimRequested").withArgs(wallet0.address, 0);
    });
  });

  context("#fulfillClaim", () => {
    let requestId: string;

    this.beforeEach("make a claim request", async () => {
      requestId = await getRequestId(await token.claim(0));
    });

    it("fails if the address doesn't have the required role", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.NO_ACCESS))
        .to.be.revertedWithCustomError(token, "NoAccess")
        .withArgs(wallet0.address);
    });

    it("fails if the check failed or invalid data was returned by the oracle", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.CHECK_FAILED))
        .to.be.revertedWithCustomError(token, "AccessCheckFailed")
        .withArgs(wallet0.address);
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, `${"0x".padEnd(65, "0")}3`))
        .to.be.revertedWithCustomError(token, "AccessCheckFailed")
        .withArgs(wallet0.address);
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, `${"0x".padEnd(65, "0")}9`))
        .to.be.revertedWithCustomError(token, "AccessCheckFailed")
        .withArgs(wallet0.address);
    });

    it("emits HasAccess event", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS))
        .to.be.emit(token, "HasAccess")
        .withArgs(wallet0.address);
    });

    it("fails if the claim was already fulfilled", async () => {
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS)).to.be.revertedWith(
        "Must have a valid requestId"
      );
      // Note: the above error is thrown by the Chainlink Operator contract. However, a non-official/malicious
      // implementation might skip that check. In those cases, the below check will still prevent double fulfills:
      // await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS)).to.be.revertedWith(
      //   "Source must be the oracle of the request"
      // );
    });

    it("should set the address's claim status", async () => {
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      expect(await token.hasClaimed(wallet0.address, 0)).to.eq(true);
    });

    it("should mint the token", async () => {
      const tokenId = await token.totalSupply();
      expect(await token.balanceOf(wallet0.address)).to.eq("0");
      await expect(token.ownerOf(tokenId)).to.be.revertedWith("ERC721: invalid token ID");
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      expect(await token.balanceOf(wallet0.address)).to.eq(1);
      expect(await token.ownerOf(tokenId)).to.eq(wallet0.address);
    });

    it("emits Claimed event", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS))
        .to.emit(token, "Claimed")
        .withArgs(wallet0.address, 0);
    });
  });
});
