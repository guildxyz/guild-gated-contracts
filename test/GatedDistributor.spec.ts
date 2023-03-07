import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, ContractTransaction } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

async function blockTimestamp() {
  const { timestamp } = await ethers.provider.getBlock("latest");
  return timestamp;
}

async function increaseTime(delta: Number): Promise<void> {
  await ethers.provider.send("evm_increaseTime", [delta]);
  await ethers.provider.send("evm_mine", []);
}

async function getRequestId(tx: ContractTransaction): Promise<string> {
  const res = await tx.wait();
  // Assuming the first event's name is ChainlinkRequested
  expect(res.logs[0].topics[0]).to.eq("0xb5e6e01e79f91267dc17b4e6314d5d4d03593d2ceee0fbb452b750bd70ea5af9");
  // The first indexed parameter of ChainlinkRequested is the requestId
  return res.logs[0].topics[1]; // eslint-disable-line prefer-destructuring
}

async function setBalance(token: Contract, to: string, amount: BigNumber) {
  const old: BigNumber = await token.balanceOf(to);
  if (old.lt(amount)) await token.mint(to, amount.sub(old));
  else if (old.gt(amount)) await token.burn(to, old.sub(amount));
}

let distributor: Contract;

let rewardToken: Contract;
const rewardAmount = ethers.utils.parseEther("1");
const distributionDuration = 86400;
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

describe("GatedDistributor", function () {
  this.beforeAll("deploy tokens and oracle", async () => {
    [wallet0, wallet1] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("MockERC20");
    const submittedRewardToken = await Token.deploy("OwoToken", "OWO");

    const LINK = await ethers.getContractFactory("MockERC677");
    const submittedLinkToken = await LINK.deploy("Link Token", "LINK");

    rewardToken = await submittedRewardToken.deployed();
    chainlinkToken = await submittedLinkToken.deployed();

    const Operator = await ethers.getContractFactory("MockOperator");
    const submittedOperator = await Operator.deploy(chainlinkToken.address);
    chainlinkOperator = await submittedOperator.deployed();
  });

  this.beforeEach("deploy distributor", async () => {
    const GatedDistributor = await ethers.getContractFactory("GatedDistributor");
    distributor = await GatedDistributor.deploy(
      rewardToken.address,
      rewardAmount,
      distributionDuration,
      guildId,
      rewardedRole,
      chainlinkToken.address,
      chainlinkOperator.address,
      jobId,
      oracleFee
    );
    await distributor.deployed();
  });

  context("#constructor", () => {
    it("fails if called with invalid parameters", async () => {
      const GatedDistributor = await ethers.getContractFactory("GatedDistributor");
      await expect(
        GatedDistributor.deploy(
          ethers.constants.AddressZero,
          rewardAmount,
          distributionDuration,
          guildId,
          rewardedRole,
          chainlinkToken.address,
          chainlinkOperator.address,
          jobId,
          oracleFee
        )
      ).to.be.revertedWithCustomError(distributor, "InvalidParameters");
      await expect(
        GatedDistributor.deploy(
          rewardToken.address,
          0,
          distributionDuration,
          guildId,
          rewardedRole,
          chainlinkToken.address,
          chainlinkOperator.address,
          jobId,
          oracleFee
        )
      ).to.be.revertedWithCustomError(distributor, "InvalidParameters");
      await expect(
        GatedDistributor.deploy(
          rewardToken.address,
          rewardAmount,
          0,
          guildId,
          rewardedRole,
          chainlinkToken.address,
          chainlinkOperator.address,
          jobId,
          oracleFee
        )
      ).to.be.revertedWithCustomError(distributor, "InvalidParameters");
      await expect(
        GatedDistributor.deploy(
          rewardToken.address,
          rewardAmount,
          distributionDuration,
          guildId,
          rewardedRole,
          ethers.constants.AddressZero,
          chainlinkOperator.address,
          jobId,
          oracleFee
        )
      ).to.be.revertedWithCustomError(distributor, "InvalidParameters");
      await expect(
        GatedDistributor.deploy(
          rewardToken.address,
          rewardAmount,
          distributionDuration,
          guildId,
          rewardedRole,
          chainlinkToken.address,
          ethers.constants.AddressZero,
          jobId,
          oracleFee
        )
      ).to.be.revertedWithCustomError(distributor, "InvalidParameters");
    });

    it("should initialize state variables", async () => {
      expect(await distributor.rewardToken()).to.eq(rewardToken.address);
      expect(await distributor.rewardAmount()).to.eq(rewardAmount);
      expect(await distributor.distributionEnd()).to.closeTo((await blockTimestamp()) + distributionDuration, 5);
      expect(await distributor.rewardedRole()).to.eq(rewardedRole);
    });
  });

  context("#claim", () => {
    it("fails if distribution ended", async () => {
      await increaseTime(distributionDuration + 1);
      await expect(distributor.claim(0))
        .to.be.revertedWithCustomError(distributor, "DistributionEnded")
        .withArgs(await blockTimestamp(), await distributor.distributionEnd());
    });

    it("fails if the address has already claimed", async () => {
      await setBalance(rewardToken, distributor.address, rewardAmount);
      const requestId = await getRequestId(await distributor.claim(0));
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      await expect(distributor.claim(0)).to.be.revertedWithCustomError(distributor, "AlreadyClaimed");
    });

    it("fails if distributor has not enough tokens", async () => {
      await setBalance(rewardToken, distributor.address, BigNumber.from(0));
      await expect(distributor.claim(0)).to.be.revertedWithCustomError(distributor, "OutOfTokens");
    });

    it("should successfully make claim requests", async () => {
      await setBalance(rewardToken, distributor.address, rewardAmount.mul(2));
      const tx0 = await distributor.claim(0);
      const res0 = await tx0.wait();
      expect(res0.status).to.equal(1);
      const tx1 = await distributor.connect(wallet1).claim(0);
      const res1 = await tx1.wait();
      expect(res1.status).to.equal(1);
    });

    it("emits ClaimRequested event", async () => {
      await setBalance(rewardToken, distributor.address, rewardAmount);
      await expect(distributor.claim(0)).to.emit(distributor, "ClaimRequested").withArgs(wallet0.address, 0);
    });
  });

  context("#fulfillClaim", () => {
    let requestId: string;

    this.beforeEach("make a claim request", async () => {
      await setBalance(rewardToken, distributor.address, rewardAmount.mul(2));
      requestId = await getRequestId(await distributor.claim(0));
    });

    it("fails if the address doesn't have the required role", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.NO_ACCESS))
        .to.be.revertedWithCustomError(distributor, "NoAccess")
        .withArgs(wallet0.address);
    });

    it("fails if the check failed or invalid data was returned by the oracle", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.CHECK_FAILED))
        .to.be.revertedWithCustomError(distributor, "AccessCheckFailed")
        .withArgs(wallet0.address);
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, `${"0x".padEnd(65, "0")}3`))
        .to.be.revertedWithCustomError(distributor, "AccessCheckFailed")
        .withArgs(wallet0.address);
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, `${"0x".padEnd(65, "0")}9`))
        .to.be.revertedWithCustomError(distributor, "AccessCheckFailed")
        .withArgs(wallet0.address);
    });

    it("emits HasAccess event", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS))
        .to.be.emit(distributor, "HasAccess")
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
      expect(await distributor.hasClaimed(wallet0.address, 0)).to.eq(true);
    });

    it("fails if token transfer fails", async () => {
      const BadToken = await ethers.getContractFactory("MockBadERC20");
      const badToken = await BadToken.deploy();
      const GatedDistributor = await ethers.getContractFactory("GatedDistributor");
      distributor = await GatedDistributor.deploy(
        badToken.address,
        rewardAmount,
        distributionDuration,
        guildId,
        rewardedRole,
        chainlinkToken.address,
        chainlinkOperator.address,
        jobId,
        oracleFee
      );
      await distributor.deployed();
      await setBalance(badToken, distributor.address, rewardAmount);
      requestId = await getRequestId(await distributor.claim(0));

      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS))
        .to.be.revertedWithCustomError(distributor, "TransferFailed")
        .withArgs(badToken.address, distributor.address, wallet0.address);
    });

    it("should transfer the tokens", async () => {
      const oldBalance = await rewardToken.balanceOf(wallet0.address);
      await chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS);
      expect(await rewardToken.balanceOf(wallet0.address)).to.eq(oldBalance.add(rewardAmount));
    });

    it("emits Claimed event", async () => {
      await expect(chainlinkOperator.tryFulfillOracleRequest(requestId, oracleResponse.ACCESS))
        .to.emit(distributor, "Claimed")
        .withArgs(wallet0.address, 0);
    });
  });

  context("#prolongDistributionPeriod", () => {
    it("fails if not called by the owner", async () => {
      await expect(distributor.connect(wallet1).prolongDistributionPeriod(990)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("sets a new, higher distribution end", async () => {
      const addition = BigNumber.from(distributionDuration);
      const oldPeriod = await distributor.distributionEnd();
      await distributor.prolongDistributionPeriod(addition);
      const newPeriod = await distributor.distributionEnd();
      expect(newPeriod).to.eq(oldPeriod.add(addition));
    });

    it("allows claiming with a new distribution period", async () => {
      await increaseTime(distributionDuration + 120);
      await expect(distributor.claim(0))
        .to.be.revertedWithCustomError(distributor, "DistributionEnded")
        .withArgs(await blockTimestamp(), await distributor.distributionEnd());
      await distributor.prolongDistributionPeriod(990);
      const tx = await distributor.claim(0);
      const res = await tx.wait();
      expect(res.status).to.eq(1);
    });

    it("emits DistributionProlonged event", async () => {
      const addition = 99;
      await expect(distributor.prolongDistributionPeriod(addition))
        .to.emit(distributor, "DistributionProlonged")
        .withArgs(await distributor.distributionEnd());
    });
  });

  context("#withdraw", () => {
    it("fails if not called by the owner", async () => {
      await expect(distributor.connect(wallet1).withdraw(wallet0.address)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("fails if distribution period has not ended yet", async () => {
      await expect(distributor.withdraw(wallet0.address))
        .to.be.revertedWithCustomError(distributor, "DistributionOngoing")
        .withArgs(await blockTimestamp(), await distributor.distributionEnd());
    });

    it("fails if there's nothing to withdraw", async () => {
      await increaseTime(distributionDuration + 1);
      await setBalance(rewardToken, distributor.address, BigNumber.from(0));
      await expect(distributor.withdraw(wallet0.address)).to.be.revertedWithCustomError(
        distributor,
        "AlreadyWithdrawn"
      );
    });

    it("transfers tokens to the recipient", async () => {
      await setBalance(rewardToken, distributor.address, BigNumber.from(101));
      await increaseTime(distributionDuration + 1);
      const oldBalance = await rewardToken.balanceOf(distributor.address);
      await distributor.withdraw(wallet0.address);
      const newBalance = await rewardToken.balanceOf(distributor.address);
      expect(oldBalance).to.eq(BigNumber.from(101));
      expect(newBalance).to.eq(BigNumber.from(0));
    });

    it("emits Withdrawn event", async () => {
      await setBalance(rewardToken, distributor.address, BigNumber.from(101));
      await increaseTime(distributionDuration + 1);
      await expect(distributor.withdraw(wallet0.address))
        .to.emit(distributor, "Withdrawn")
        .withArgs(wallet0.address, BigNumber.from(101));
    });
  });
});
