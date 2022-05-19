// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

contract VanityNameRegistry {
    uint32 public timeLockPeriod;
    uint32 public lockValue;
    address owner;
    bool locked;
    constructor(uint32 _timeLockPeriod, uint32 _lockValue){
        timeLockPeriod = _timeLockPeriod;
        lockValue = _lockValue;
        owner = msg.sender;
        locked = false;
    }
    struct Person {
        string name;
        uint256 value;
        bool isLocked;
    }
    mapping(address => Person) nameBook;
    mapping(string => address) ownerByname;

    function register(string memory _name) public payable {
        require(msg.value > lockValue, "You need to pay the registration fee");
        nameBook[msg.sender].name = _name;
        nameBook[msg.sender].value = msg.value;
        nameBook[msg.sender].isLocked = true;
    }

    

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    function setTimeLockPeriod  (uint32 _timeLockPeriod) external  onlyOwner {
        timeLockPeriod = _timeLockPeriod;
    }
    function setLockValue  (uint32 _lockValue) external  onlyOwner {
        lockValue = _lockValue;
    }

    function getName(address _owner) public view returns (string memory) {
        return nameBook[_owner].name;
    }

    function getValue(address _owner) public view returns (uint256) {
        return nameBook[_owner].value;
    }

    function getOwner(string memory _name) public view returns (address) {
        return ownerByname[_name];
    }
}