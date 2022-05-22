const GenuinoNameRegistry = artifacts.require("GenuinoNameRegistry");

module.exports = async function (deployer) {
  await deployer.deploy(GenuinoNameRegistry, 300);
};