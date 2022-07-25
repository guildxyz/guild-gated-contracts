import { expect } from "chai";
import { ethers } from "hardhat";

// Tests written in TypeScript
describe("Greeter - TS test", function () {
  this.beforeEach("deploy contract", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    this.greeter = await Greeter.deploy("Hello, world!");
    await this.greeter.deployed();
  });

  it("Should return the new greeting once it's changed", async function () {
    expect(await this.greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await this.greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await this.greeter.greet()).to.equal("Hola, mundo!");
  });

  it("should revert if the greeting is too short", async function () {
    const greeting = "Hey";
    expect(this.greeter.setGreeting(greeting))
      .to.be.revertedWithCustomError(this.greeter, "NameTooShort")
      .withArgs("3", "4");
  });

  it("should emit a GreetingUpdated event", async function () {
    const greeting = "Hey, wassup";
    expect(this.greeter.setGreeting(greeting))
      .to.emit(this.greeter, "GreetingUpdated")
      .withArgs(greeting);
  });
});
