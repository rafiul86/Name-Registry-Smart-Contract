const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Box = artifacts.require('Box');

module.exports = async function (deployer) {
  await deployProxy(Box, ['0xbC4E3F144727aE4B701680DB3F05dA03a4e48340'], { deployer, initializer: 'initialize' });
};