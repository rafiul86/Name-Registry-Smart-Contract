const { expect } = require("chai");
const { ethers } = require("hardhat");
const crypto = require("crypto");

// increse time in seconds
const increaseTimeInSeconds = async (seconds, mine = false) => {
  await ethers.provider.send("evm_increaseTime", [seconds]);
  if (mine) {
    await ethers.provider.send("evm_mine", []);
  }
};

// VNRS test for name registration Service
describe("Vanity Name Registration Service", function () {
  let user1, user2, user3, user4, user5;
  let GNS;

  this.beforeEach(async () => {
    const GenuinoNameRegistry = await ethers.getContractFactory("GenuinoNameRegistry");
    GNS = await GenuinoNameRegistry.deploy(300);
    await GNS.deployed();
    [user1, user2, user3, user4, user5] = await ethers.getSigners();
  });

  it("Should register the desired name", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user1).generateCondition("GENUINO", secretPass);
    console.log("Condition: " + condition);

    await GNS.connect(user1).condition(condition);

    await increaseTimeInSeconds(100, true);

    await expect(
      GNS
        .connect(user1)
        .registerName("GENUINO", secretPass, { value: ethers.utils.parseEther("4") })
    )
      .to.emit(GNS, "NameRegistered")
      .withArgs(user1.address, "GENUINO", ethers.utils.parseEther("3"), );
  });
});