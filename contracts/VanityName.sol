// SPDX-License-Identifier: NONE

pragma solidity ^0.8.14;

contract VanityNameRegistry {
    uint32 public timeLockPeriod;
    uint public lockValue = 1 ether;
    address owner;
    bool locked;
    constructor(uint32 _timeLockPeriod){
        timeLockPeriod = _timeLockPeriod;
        owner = msg.sender;
        locked = false;
    }
    struct Person {
        string name;
        uint256 value;
        uint256 time;
        bool isLocked;
    }
    mapping(address => Person) nameBook;
    mapping(string => address) ownerByname;

    function registerName(string memory _name) public payable {
        require(msg.value >= lockValue, "You need to pay the registration fee");
        nameBook[msg.sender].name = _name;
        nameBook[msg.sender].value = msg.value;
        nameBook[msg.sender].isLocked = true;
        nameBook[msg.sender].time = block.timestamp + timeLockPeriod;
        ownerByname[_name] = msg.sender;
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
        return nameBook[_ownerAddress].name;
    }
    function getNameCallByOwner() public view returns (string memory) {
        return nameBook[msg.sender].name;
    }

    function getValue(address _owner) public view returns (uint256) {
        return nameBook[_owner].value;
    }

    function removeName(address _removableNameAddress) external {
        nameBook[_removableNameAddress].name = " ";
    }

    function withDrawLockValue () external {
        require(block.timestamp > nameBook[msg.sender].time, "Too early");
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