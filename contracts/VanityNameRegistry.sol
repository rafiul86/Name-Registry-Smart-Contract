// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

  
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract VanityNameRegistry {
    // using openzeppelin safemath to prevent overflow and underflow of integers math operation
    using SafeMath for uint256;
    using SafeMath for uint;
    uint public timeLockPeriod;
    uint lockValue = 3 ether;
    uint nameCount;
    address public owner;
    bool locked;
    address [] public nameToOwner;
    constructor(uint32 _timeLockPeriod){
        timeLockPeriod = _timeLockPeriod;
        owner = msg.sender;
        locked = false;
    }
    struct NameBook {
        bytes name;
        uint256 value;
        uint256 time;
        bool isLocked;
    }
    mapping(address => NameBook) nameBook;
    mapping(string => address) ownerByname;

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    event NameRegistered(address indexed caller, bytes indexed name, uint256 value);
    event NameUnregistered(address indexed caller, bytes indexed name);
    event NameChanged(address indexed caller, bytes indexed name, uint256 value);
    event SetTimePeriod(uint timeLockPeriod);
    event BalanceWithdwalFromAccount(address indexed caller, uint256 value);
    event BalanceWithdwalByNameHolder(address indexed caller, uint256 value);
    event NameRemoval(address indexed caller, bytes indexed name);
    event Operational(bool operationalStatus);

    function setregistrationFee(string memory _myString) pure private returns (uint) {
        bytes memory sizeOfString = bytes(_myString);
        uint valueForLock = uint(sizeOfString.length) * 10**18;
        return valueForLock;
    }

    function registerName(string memory _name) public payable {
        uint registrationFee = setregistrationFee(_name);
        uint valueForLock = lockValue.add(registrationFee);
        require(msg.value >= valueForLock, "Not enough value to register name");
        require(!locked, "Account is locked");
        bytes memory nameFromString = bytes(_name);
        uint256 timeLock =  timeLockPeriod.add(block.timestamp);
        nameBook[msg.sender] = NameBook({name: nameFromString, value: lockValue, time: timeLock, isLocked: true});
        nameToOwner.push(msg.sender);
        ownerByname[_name] = msg.sender;
        nameCount++;
        emit NameRegistered(msg.sender, nameFromString, lockValue);  
        if (msg.value > valueForLock) {
            // extra amount paid by the user should be refunded
            (bool success, ) = payable(msg.sender).call{value: msg.value - valueForLock}("");
            require(success, "refund not succcessful");
        }   
    }

    function checkExpiry()external onlyOwner{
        for(uint i=0; i < nameToOwner.length; i++ ){
            if (nameBook[nameToOwner[i]].time < block.timestamp){
                nameBook[nameToOwner[i]].name = " ";
                nameBook[nameToOwner[i]].time = 0;
                nameBook[nameToOwner[i]].isLocked = false;
                delete nameToOwner[i];
                nameCount--;
            }
        }
    }

    function setTimeLockPeriod  (uint _timeLockPeriod) external  onlyOwner {
        timeLockPeriod = _timeLockPeriod;
        emit SetTimePeriod(timeLockPeriod);
    }
    
    function setOpeartionalStatus(bool _operationalStatus) external onlyOwner {
        locked = _operationalStatus;
        emit Operational(_operationalStatus);
    }

    function withdrawAccountBalance () external onlyOwner {
      require(!locked, "Account is locked");
      require(address(this).balance > 0, "Balance is zero");
      payable (msg.sender).transfer(address(this).balance);
      emit BalanceWithdwalFromAccount(msg.sender, address(this).balance);
    }

    function removeName(address _removableNameAddress) external onlyOwner {
        require(!locked, "Account is locked");
        nameBook[_removableNameAddress].name = " ";
        nameBook[_removableNameAddress].time = 0;
        nameBook[msg.sender].isLocked = false;
        nameCount--;
        emit NameRemoval(msg.sender, nameBook[_removableNameAddress].name);
    }

    function withDrawLockValue () external payable {
        require(!locked, "Account is locked");
        require(block.timestamp > nameBook[msg.sender].time, "Too early");
        require(!nameBook[msg.sender].isLocked, "Name service in action, wait till expire");
        require(nameBook[msg.sender].value > 0, "locked value exceeds");
        uint withdrawableBalance = nameBook[msg.sender].value;
        nameBook[msg.sender].value = 0;
        payable(msg.sender).transfer(withdrawableBalance);
        emit BalanceWithdwalByNameHolder(msg.sender, withdrawableBalance);
    }

    function getOwner(string memory _name) public view returns (address) {
        return ownerByname[_name];
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTotalRegisteredName() public view returns (uint) {
        return nameCount;
    }

    function getOperationalStatus() public view returns(bool){
        return locked;
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

    fallback () external payable {

    }

    receive() external payable {
        
    }
}