// This script is designed to test the solidity smart contract - GenuinoNameRegistry.sol -- and the various functions within
// variable and assign the compiled smart contract artifact
const GenuinoNameRegistry = artifacts.require('GenuinoNameRegistry.sol');
const BigNumber = require('bignumber.js');
const crypto = require("crypto");
const web3 = require('web3');
const time = require('./helper.js')

contract('GenuinoNameRegistry', async function(accounts) {

    // Test variables
      let genuinoNameRegistry;  
      let user1, user2, user3;
      [user1, user2, user3, user4, user5] = accounts.slice(0,5);

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
        await time.increase(time.duration.seconds(100));
        let result = await genuinoNameRegistry.registerName("genuino", secretHash);
        
        assert.equal(result, true);
        });
    });