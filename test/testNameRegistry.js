// This script is designed to test the solidity smart contract - GenuinoNameRegistry.sol -- and the various functions within
// variable and assign the compiled smart contract artifact
const GenuinoNameRegistry = artifacts.require('GenuinoNameRegistry.sol');
const { ethers } = require("ethers");
const web3 = require('web3');
const BigNumber = require('bignumber.js');
const crypto = require("crypto");
const utils = require('./helper/time.js');
  

contract('GenuinoNameRegistry', async function(accounts) {
      let genuinoNameRegistry;  
      let user1, user2, user3;
      [user1, user2, user3, user4, user5] = accounts.slice(0,5);

      // increse time in seconds
    const increaseTimeInSeconds = async (seconds, mine = false) => {
        await ethers.provider.send("evm_increaseTime", [seconds]);
        if (mine) {
        await ethers.provider.send("evm_mine", []);
        }
    };
   
    it('deposit 3 ether to register name', async () => {
    
        genuinoNameRegistry = await GenuinoNameRegistry.deployed()
        // deposit 3 ether to register name
        let lockedValue = "3000000000000000000"
       
        let result = await genuinoNameRegistry.lockValue();
    
        // assert to check required amount deposited prior to registration
        assert.equal(result, lockedValue, "lockedvalue 3 ether");
    
      });

      it("Should register the desired name", async function () {
        const secretBytes = crypto.randomBytes(16);
        genuinoNameRegistry = await GenuinoNameRegistry.deployed()
        const secretHash = await genuinoNameRegistry.generateCondition("genuino", secretBytes);
            
        await genuinoNameRegistry.condition(secretHash);
        await utils.timeTravel(web3, 100);
        let result = await genuinoNameRegistry.registerName("genuino", secretHash);
        
        assert.equal(result, true);
        });
    });