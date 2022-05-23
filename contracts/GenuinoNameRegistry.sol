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


contract GenuinoNameRegistry {

    // using openzeppelin safemath to prevent overflow and underflow of integers math operation
    using SafeMath for uint256;
    using SafeMath for uint;
    uint public timeLockPeriod = 604800; // 7 days
    uint64 constant minimumDelayPeriod = 60;
    uint64 constant maximumDelayPeriod = 24*60*60;
    uint public lockValue = 3 ether;
    address public owner;
    bool locked;
    bytes32 [] public nameToOwner;

    constructor(uint32 _timeLockPeriod)  {
        timeLockPeriod = _timeLockPeriod;
        owner = msg.sender;
    }
    struct NameRecord {
        address ownerOfName;
        bytes32 name;
        uint256 value;
        uint256 endPeriod;
        bool isLocked;
    }
    
    mapping(bytes32 => NameRecord) public nameRecord;
    mapping (bytes32 => uint) preventFrontRun;

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    event NameRegistered(address indexed caller, string name, uint256 value);
    event NameUnregistered(address indexed caller, bytes32 indexed name);
    event NameChanged(address indexed caller, bytes32 indexed name, uint256 value);
    event SetTimePeriod(uint timeLockPeriod);
    event BalanceWithdwalFromAccount(address indexed caller, uint256 value);
    event BalanceWithdwalByNameHolder(address indexed caller, uint256 value);
    event NameRemoval(address indexed caller, bytes32 indexed name);
    event Renewal(bytes32 indexed name, uint256 value);
    event Operational(bool operationalStatus);

    function calculateregistrationFee(string calldata name) public pure returns (uint64) {
        return uint64(bytes(name).length) * 10**16;
    }

     function isNameAvailable(bytes32  _name) public view returns (address) {
        return nameRecord[_name].ownerOfName;
    }

     function checkFrontRunConditions(bytes32 _condition) public {
        require(preventFrontRun[_condition].add(minimumDelayPeriod) <= block.timestamp);
        require(preventFrontRun[_condition].add(maximumDelayPeriod) > block.timestamp);
        delete(preventFrontRun[_condition]);
    }

    function generateCondition(string memory _name, bytes32 _key) public view  returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(bytes(_name)), msg.sender, _key));
    }

    function condition(bytes32 _condition) public {
        require(preventFrontRun[_condition].add(maximumDelayPeriod) < block.timestamp, "ondition  exists");
        preventFrontRun[_condition] = block.timestamp;
    }

    function registerName(string calldata _name, bytes32 _secretKey) public payable {
        bytes32 nameForRgistration = keccak256(bytes(_name));
        require(isNameAvailable(nameForRgistration) == address(0), "name is not available for registration");
        bytes32 conditionToPreventFrontRun = generateCondition(_name, _secretKey);
        checkFrontRunConditions(conditionToPreventFrontRun);
        uint registrationFee = calculateregistrationFee(_name);
        uint valueForLock = lockValue.add(registrationFee);
        require(msg.value >= valueForLock, "Not enough value to register name");
        require(!locked, "Account is locked");
        uint256 timeLock =  timeLockPeriod.add(block.timestamp);
        nameRecord[nameForRgistration] = NameRecord({ownerOfName: msg.sender, name: nameForRgistration, value: lockValue, endPeriod: timeLock, isLocked: true});
        nameToOwner.push(nameForRgistration);
        emit NameRegistered(msg.sender, _name, lockValue);  
        if (msg.value > valueForLock) {
            // extra amount paid by the user should be refunded
            (bool success, ) = payable(msg.sender).call{value: msg.value - valueForLock}("");
            require(success, "refund not succcessful");
        }   
    }

    function resetExpiredNameFromRecord()external onlyOwner{
        for(uint i=0; i < nameToOwner.length; i++ ){
            if (nameRecord[nameToOwner[i]].endPeriod < block.timestamp){
                nameRecord[nameToOwner[i]].name = " ";
                nameRecord[nameToOwner[i]].endPeriod = 0;
                nameRecord[nameToOwner[i]].isLocked = false;
                delete nameToOwner[i];
            }
        }
    }

    function renewalOfName(string calldata _name) external {
        bytes32 nameForRenew = keccak256(bytes(_name));
        require(nameRecord[nameForRenew].ownerOfName == msg.sender, "you are not owner of this name");
        require(nameRecord[nameForRenew].endPeriod > block.timestamp, "Name is expired");
        nameRecord[nameForRenew].endPeriod += timeLockPeriod;
        emit Renewal(nameForRenew, nameRecord[nameForRenew].endPeriod);
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

    function removeName(string calldata _name) external onlyOwner {
        require(!locked, "Account is locked");
        bytes32 nameForRemoval = keccak256(bytes(_name));
        nameRecord[nameForRemoval].name = " ";
        nameRecord[nameForRemoval].endPeriod = 0;
        nameRecord[nameForRemoval].ownerOfName = address(0);
        nameRecord[nameForRemoval].isLocked = false;
        emit NameRemoval(msg.sender, nameRecord[nameForRemoval].name);
    }

    function withDrawLockValue (string calldata _name) external payable {
        require(!locked, "Account is locked");
        bytes32 nameForWithdrawalValue = keccak256(bytes(_name));
        require(!locked, "Contract is locked");
        require(nameRecord[nameForWithdrawalValue].ownerOfName == msg.sender, "Only owner can withdraw");
        require(block.timestamp > nameRecord[nameForWithdrawalValue].endPeriod, "Too early");
        require(!nameRecord[nameForWithdrawalValue].isLocked, "Name service in action, wait till expire");

        uint withdrawableBalance = nameRecord[nameForWithdrawalValue].value;
        nameRecord[nameForWithdrawalValue].value = 0;
        payable(msg.sender).transfer(withdrawableBalance);
        emit BalanceWithdwalByNameHolder(msg.sender, withdrawableBalance);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getOperationalStatus() public view returns(bool){
        return locked;
    }

    fallback () external payable {

    }

    receive() external payable {
        
    }
}