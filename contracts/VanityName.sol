// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

contract VanityName {
    uint32 public timeLockPeriod;
    address owner;
    bool locked;
    constructor(uint32 _timeLockPeriod){
        timeLockPeriod = _timeLockPeriod;
        owner = msg.sender;
        locked = false;
    }
    struct Person {
        bytes name;
        uint256 value;
        uint256 time;
        bool isLocked;
    }
    mapping(address => Person) nameBook;
    mapping(string => address) ownerByname;

    function registerName(string memory _name) public payable {
        bytes memory nameFromString = bytes(_name);
        uint lockValue;
        require(msg.value >= lockValue, "You need to pay the registration fee");
        if (nameFromString.length >= 8) {
            lockValue = 1 ether;
            
            if (msg.value > lockValue){
                uint extraValue = msg.value - lockValue;
                payable(msg.sender).transfer(extraValue);
                uint remainingValue = msg.value - extraValue;
                nameBook[msg.sender].name = nameFromString;
                nameBook[msg.sender].value = remainingValue;
                nameBook[msg.sender].isLocked = true;
                nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
            } else {
                nameBook[msg.sender].name = nameFromString;
                nameBook[msg.sender].value = msg.value;
                nameBook[msg.sender].isLocked = true;
                nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
            }        
        } else if (nameFromString.length >= 16) {
            lockValue = 2 ether;
        
            if (msg.value > lockValue){
                uint extraValue = msg.value - lockValue;
                payable(msg.sender).transfer(extraValue);
                uint remainingValue = msg.value - extraValue;
                nameBook[msg.sender].name = nameFromString;
                nameBook[msg.sender].value = remainingValue;
                nameBook[msg.sender].isLocked = true;
                nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
            } else {
                nameBook[msg.sender].name = nameFromString;
                nameBook[msg.sender].value = msg.value;
                nameBook[msg.sender].isLocked = true;
                nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
            }        
        }else if (nameFromString.length >= 32){
            lockValue = 3 ether;
        
        if (msg.value > lockValue){
            uint extraValue = msg.value - lockValue;
            payable(msg.sender).transfer(extraValue);
            uint remainingValue = msg.value - extraValue;
            nameBook[msg.sender].name = nameFromString;
            nameBook[msg.sender].value = remainingValue;
            nameBook[msg.sender].isLocked = true;
            nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
        } else {
            nameBook[msg.sender].name = nameFromString;
            nameBook[msg.sender].value = msg.value;
            nameBook[msg.sender].isLocked = true;
            nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
        }        
        } else {
            lockValue = 4 ether;
        
        if (msg.value > lockValue){
            uint extraValue = msg.value - lockValue;
            payable(msg.sender).transfer(extraValue);
            uint remainingValue = msg.value - extraValue;
            nameBook[msg.sender].name = nameFromString;
            nameBook[msg.sender].value = remainingValue;
            nameBook[msg.sender].isLocked = true;
            nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
        } else {
            nameBook[msg.sender].name = nameFromString;
            nameBook[msg.sender].value = msg.value;
            nameBook[msg.sender].isLocked = true;
            nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
        }        
        }
        
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    function setTimeLockPeriod  (uint32 _timeLockPeriod) external  onlyOwner {
        timeLockPeriod = _timeLockPeriod;
    }
   
    function withdraw () external onlyOwner {
      require(address(this).balance > 0, "Balance is zero");
      payable (msg.sender).transfer(address(this).balance);
    }

    function checkBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getName(address _ownerAddress) public view returns (string memory) {
        string memory nameFromBytes = string(nameBook[_ownerAddress].name);
        return nameFromBytes;
    }
    function getNameCallByOwner() public view returns (string memory) {
        string memory nameFromBytes = string(nameBook[msg.sender].name);
        return nameFromBytes;
    }

    function getValue(address _owner) public view returns (uint256) {
        return nameBook[_owner].value;
    }

    function removeName(address _removableNameAddress) external {
        nameBook[_removableNameAddress].name = " ";
        nameBook[_removableNameAddress].time = 0;
        nameBook[msg.sender].isLocked = false;
    }

    function withDrawLockValue () external {
        require(block.timestamp > nameBook[msg.sender].time, "Too early");
        require(nameBook[msg.sender].isLocked == false, "Name service in action, wait till expire");
        uint withdrawableBalance = nameBook[msg.sender].value;
        nameBook[msg.sender].value = 0;
        payable(msg.sender).transfer(withdrawableBalance);
    }

    function getOwner(string memory _name) public view returns (address) {
        return ownerByname[_name];
    }

    function getBytesSize(string memory _myString) pure external returns(uint){
        bytes memory sizeOfString = bytes(_myString);
        return sizeOfString.length;
    }


    fallback () external payable {

    }

    receive() external payable {
        
    }
}