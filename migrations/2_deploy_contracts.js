const GenuinoNameRegistry = artifacts.require("GenuinoNameRegistry");

module.exports = async function (deployer) {
  await deployer.deploy(GenuinoNameRegistry, 604800, 86400);
};