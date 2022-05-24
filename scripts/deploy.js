// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
 
  // We get the contract to deploy
  const GenuinoNameRegistry = await hre.ethers.getContractFactory("GenuinoNameRegistry");
  const GNS = await GenuinoNameRegistry.deploy(604800, 86400);

  await GNS.deployed();

  console.log("GNS smart contract deployed to:", GNS.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  