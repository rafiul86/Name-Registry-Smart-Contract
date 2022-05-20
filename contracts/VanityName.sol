// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

contract VanityName {
    uint32 public timeLockPeriod;
    uint public lockValue = 0.0001 ether;
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
        require(msg.value >= lockValue, "You need to pay the registration fee");
       bytes memory nameFromString = bytes(_name);
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

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    function setTimeLockPeriod  (uint32 _timeLockPeriod) external  onlyOwner {
        timeLockPeriod = _timeLockPeriod;
    }
    function setLockValue  (uint _lockValue) external  onlyOwner {
        lockValue = _lockValue;
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

    fallback () external payable {

    }

    receive() external payable {
        
    }
}