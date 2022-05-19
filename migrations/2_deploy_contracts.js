const VanityName = artifacts.require("VanityName");

module.exports = async function (deployer) {
  await deployer.deploy(VanityName, 300);
};