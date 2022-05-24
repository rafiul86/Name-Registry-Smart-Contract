const { expect } = require("chai");
const { ethers } = require("hardhat");
const crypto = require("crypto");

// increse time in seconds
const timeTravel = async (seconds, mine = false) => {
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
    GNS = await GenuinoNameRegistry.deploy(30);
    await GNS.deployed();
    // global variables
    [user1, user2, user3, user4, user5] = await ethers.getSigners();
  });

  // 1st test
  it("register the desired name with lockedValue and secret pass", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user1).generateCondition("GENUINO", secretPass);
    console.log("Condition: " + condition);

    await GNS.connect(user1).condition(condition);

    await timeTravel(100, true);

    await expect(
      GNS
        .connect(user1)
        .registerName("GENUINO", secretPass, { value: ethers.utils.parseEther("4") })
    )
      .to.emit(GNS, "NameRegistered")
      .withArgs(user1.address, "GENUINO", ethers.utils.parseEther("3"), );
  });


  // 2nd test
  it("Shouldn't register without condition", async function () {
    const secretPass = crypto.randomBytes(64);

    await expect(
      GNS
        .connect(user1)
        .registerName("GENUINO", secretPass, { value: ethers.utils.parseEther("4") })
    ).to.be.reverted;
  });


  // 3rd test
  it("only owner of contract can set operational ststus", async function () {
    await expect(
      GNS.connect(user3).setOpeartionalStatus(true)
    ).to.be.revertedWith("Caller is not owner of registry service");
  });

  // 4th test
  it("Should be able to withdraw funds if name is expired", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretPass);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);
    await GNS.connect(user2).registerName("genuino", secretPass, { value: ethers.utils.parseEther("5") });
    await timeTravel(100, true);
    await GNS.connect(user1).resetExpiredNameFromRecord();
    
    await expect(GNS.connect(user2).withDrawLockValue("genuino")).to.emit(GNS, "BalanceWithdwalByNameHolder");
  });

  // 5th test
  it("Shouldn't be able to withdraw funds if name is not expired", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretPass);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);
    await GNS.connect(user2).registerName("genuino", secretPass, { value: ethers.utils.parseEther("5") });
    
    await expect(GNS.connect(user2).withDrawLockValue("genuino")).to.be.revertedWith("Too early");
  });
  // 6th test
  it("user can be able renew before expiry after paying renewal fee", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretPass);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);

    await GNS.connect(user2).registerName("genuino", secretPass, { value: ethers.utils.parseEther("5") });

    await expect(GNS.connect(user2).renewalOfName("genuino", { value: ethers.utils.parseEther("1")})).to.emit(GNS, "Renewal")
  });

  // 7th test
  it("only user can be able to renew", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretPass);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);

    await GNS.connect(user2).registerName("genuino", secretPass, { value: ethers.utils.parseEther("5") });

    await expect(GNS.connect(user3).renewalOfName("genuino", { value: ethers.utils.parseEther("1")})).to.be.revertedWith("you are not owner of this name")
  });

  // 8th test
  it("vm revert if name is not available", async function () {
    const secretAlpha = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretAlpha);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);

    await GNS.connect(user2).registerName("genuino", secretAlpha, { value: ethers.utils.parseEther("5") });

    const secretBeta = crypto.randomBytes(32);
    const condition2 = await GNS.connect(user2).generateCondition("genuino", secretBeta);

    await GNS.connect(user3).condition(condition2);

    await timeTravel(100, true);
    await expect(
      GNS.connect(user3).registerName("genuino", secretBeta, { value: ethers.utils.parseEther("5") })
    ).to.be.revertedWith("name is not available, try with another name");
  });

  // 9th test
  it("only owner of contract can remove name from registry", async function () {
    await expect(
      GNS.connect(user3).removeName(true)
    ).to.be.revertedWith("Caller is not owner of registry service");
  });

  // 10th test
  it("only owner of contract can withdraw contract balance collect as registration fee from user", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretPass);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);
    await GNS.connect(user2).registerName("genuino", secretPass, { value: ethers.utils.parseEther("5") });

    await expect(
      GNS.connect(user1).withdrawAccountBalance()
    ).to.emit(GNS, "BalanceWithdwalFromAccount");
  });

  // 11th test
  it("can't withdraw balance by other than owner", async function () {
    const secretPass = crypto.randomBytes(32);
    const condition = await GNS.connect(user2).generateCondition("genuino", secretPass);

    await GNS.connect(user2).condition(condition);

    await timeTravel(100, true);
    await GNS.connect(user2).registerName("genuino", secretPass, { value: ethers.utils.parseEther("5") });

    await expect(
      GNS.connect(user2).withdrawAccountBalance()
    ).to.be.revertedWith("Caller is not owner of registry service");
  });

});