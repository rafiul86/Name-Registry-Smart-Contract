// SPDX-License-Identifier: NONE
pragma solidity 0.8.14;

import "./KeeperBase.sol";
import "./KeeperCompatibleInterface.sol";
// chainlink upkeep contract for automation of checking expiration
abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

contract GenuinoNameRegistry is KeeperCompatible {

    // using openzeppelin safemath to prevent overflow and underflow of integers math operation
    using SafeMath for uint256;
    using SafeMath for uint;

      /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval; // initially 86400 = 1 day
    uint public lastTimeStamp;
    uint counter;
    // state variables
    uint public timeLockPeriod; // initial value while deploying is 7 days = 604800 seconds
    uint64 constant minimumDelayPeriod = 60; // minimum delay period to prevent frontrun and dishonest validation
    uint64 constant maximumDelayPeriod = 24*60*60;  // maximum delay period to prevent frontrun and dishonest validation
    uint public lockValue = 3 ether; // amount of ether to lock as a deposit
    address public owner;  // owner of the smart contract
    bool locked;  // indicates if the contract locked is fales means operational state 
    bytes32 [] public nameToOwner; // registered name stored in the array

    constructor(uint32 _timeLockPeriod, uint updateInterval)  {
        timeLockPeriod = _timeLockPeriod;
        owner = msg.sender;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }
    // struct to store the name variables
    struct NameRecord {
        address ownerOfName;
        bytes32 name;
        uint256 value;
        uint256 endPeriod;
        bool isLocked;
    }
    // mapping of name to name record
    mapping(bytes32 => NameRecord) public nameRecord;

    // mapping to store bytes to prevent frontrun and dishonest validation
    mapping (bytes32 => uint) preventFrontRun;

    // modifier indicates the contract owner only can call this function
    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    // events for the smart contract after performing the functions
    event NameRegistered(address indexed caller, string name, uint256 value);
    event NameUnregistered(address indexed caller, bytes32 indexed name);
    event NameChanged(address indexed caller, bytes32 indexed name, uint256 value);
    event SetTimePeriod(uint timeLockPeriod);
    event BalanceWithdwalFromAccount(address indexed caller, uint256 value);
    event BalanceWithdwalByNameHolder(address indexed caller, uint256 value);
    event NameRemoval(address indexed caller, bytes32 indexed name);
    event Renewal(bytes32 indexed name, uint256 value);
    event Operational(bool operationalStatus);

    // helper function to calculate registration fee varies on the size of the name
    function calculateregistrationFee(string calldata name) public pure returns (uint64) {
        return uint64(bytes(name).length) * 10**16;
    }
    // check if the name is available or not
     function isNameAvailable(bytes32  _name) public view returns (address) {
        return nameRecord[_name].ownerOfName;
    }

    // check the condition to prevent front run and dishonest validation prior to registration
     function checkFrontRunConditions(bytes32 _condition) public {
        require(preventFrontRun[_condition].add(minimumDelayPeriod) <= block.timestamp);
        require(preventFrontRun[_condition].add(maximumDelayPeriod) > block.timestamp);
        delete(preventFrontRun[_condition]);
    }

    // generate the random bytes from name and secret key to prevent front run and dishonest validation
    function generateCondition(string memory _name, bytes32 _key) public view  returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(bytes(_name)), msg.sender, _key));
    }

    // delay periods to prevent front run and dishonest validation
    function condition(bytes32 _condition) public {
        require(preventFrontRun[_condition].add(maximumDelayPeriod) < block.timestamp, "ondition  exists");
        preventFrontRun[_condition] = block.timestamp;
    }


    // register the name with the value defined by struct NameRecord
    function registerName(string calldata _name, bytes32 _secretKey) public payable {
        bytes32 nameForRgistration = keccak256(bytes(_name));

        // check if the name is available or not 
        require(isNameAvailable(nameForRgistration) == address(0), "name is not available, try with another name");

        // convert name and secretkey to bytes32 to prevent front run 
        bytes32 conditionToPreventFrontRun = generateCondition(_name, _secretKey);

        // check the condition to prevent front run and dishonest validation 
        checkFrontRunConditions(conditionToPreventFrontRun);
        uint registrationFee = calculateregistrationFee(_name);
        uint valueForLock = lockValue.add(registrationFee);

        // check if the caller has enough ether to register the name
        require(msg.value >= valueForLock, "Not enough value to register name");

        // should not register if contract is not in operational state
        require(!locked, "Account is locked");
        uint256 timeLock =  timeLockPeriod.add(block.timestamp);
        nameRecord[nameForRgistration] = NameRecord({ownerOfName: msg.sender, name: nameForRgistration, value: lockValue, endPeriod: timeLock, isLocked: true});

        // store the name in the array for checking the expiration of the name
        nameToOwner.push(nameForRgistration);

        // emit the event to notify the name is registered
        emit NameRegistered(msg.sender, _name, lockValue);  
        if (msg.value > valueForLock) {
            // extra amount paid by the user should be refunded
            (bool success, ) = payable(msg.sender).call{value: msg.value - valueForLock}("");
            require(success, "refund not succcessful");
        }   
    }

    // unregister the name after time expired by an external 3rd party oracle service e. g. chainlink
    // for simplycity, this function should called by owner after every 24 hours
    function resetExpiredNameFromRecord() public {
        for(uint i=0; i < nameToOwner.length; i++ ){
            if (nameRecord[nameToOwner[i]].endPeriod < block.timestamp){
                nameRecord[nameToOwner[i]].name = " ";
                nameRecord[nameToOwner[i]].endPeriod = 0;
                nameRecord[nameToOwner[i]].isLocked = false;
                delete nameToOwner[i];
            }
        }
    }

    // unregister the name after time expired by an external chainlink oracle, should be registered by owner on chainlink oracle service
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            resetExpiredNameFromRecord();
            counter++;
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    // user can renew the name anytime before the time expires
    function renewalOfName(string calldata _name) external payable {
        bytes32 nameForRenew = keccak256(bytes(_name));
        uint registrationFee = calculateregistrationFee(_name);

        // check if the caller has enough ether to renew the name
        require(msg.value >= registrationFee, "Not enough value to register name");
        require(nameRecord[nameForRenew].ownerOfName == msg.sender, "you are not owner of this name");
        // extend the time period of the name
        nameRecord[nameForRenew].endPeriod += timeLockPeriod;
        emit Renewal(nameForRenew, nameRecord[nameForRenew].endPeriod);
        if (msg.value > registrationFee) {
            // extra amount paid by the user should be refunded
            (bool success, ) = payable(msg.sender).call{value: msg.value - registrationFee}("");
            require(success, "refund not succcessful");
        } 
    }

    // owner can change the time lock period of the contract
    function setTimeLockPeriod  (uint _timeLockPeriod) external  onlyOwner {
        timeLockPeriod = _timeLockPeriod;
        emit SetTimePeriod(timeLockPeriod);
    }
    
    //owner can start or stop the contract in case of emergency
    function setOpeartionalStatus(bool _operationalStatus) external onlyOwner {
        locked = _operationalStatus;
        emit Operational(_operationalStatus);
    }


    // owner can withdraw the ether from the contract collecting as registration fee
    function withdrawAccountBalance () external onlyOwner {
      require(!locked, "Account is locked");
      require(address(this).balance > 0, "Balance is zero");
      payable (msg.sender).transfer(address(this).balance);
      emit BalanceWithdwalFromAccount(msg.sender, address(this).balance);
    }

    // owner can remove name if seen any malicious activities or conflict arises
    function removeName(string calldata _name) external onlyOwner {
        require(!locked, "Account is locked");
        bytes32 nameForRemoval = keccak256(bytes(_name));
        nameRecord[nameForRemoval].name = " ";
        nameRecord[nameForRemoval].endPeriod = 0;
        nameRecord[nameForRemoval].ownerOfName = address(0);
        nameRecord[nameForRemoval].isLocked = false;
        emit NameRemoval(msg.sender, nameRecord[nameForRemoval].name);
    }

    // owner of name can withdraw after the time expires 
    function withDrawLockValue (string calldata _name) external payable {
        require(!locked, "Account is locked");
        bytes32 nameForWithdrawalValue = keccak256(bytes(_name));
        require(!locked, "Contract is locked");
        require(nameRecord[nameForWithdrawalValue].ownerOfName == msg.sender, "Only owner can withdraw");
        require(block.timestamp > nameRecord[nameForWithdrawalValue].endPeriod, "Too early");
        require(!nameRecord[nameForWithdrawalValue].isLocked, "Name service in action, wait till expire");

        uint withdrawableBalance = nameRecord[nameForWithdrawalValue].value;
        
        // make the value zero first to prevent re-entrancy
        nameRecord[nameForWithdrawalValue].value = 0;

        // transfer the ether to the caller
        payable(msg.sender).transfer(withdrawableBalance);
        emit BalanceWithdwalByNameHolder(msg.sender, withdrawableBalance);
    }


    // get total balance held by the contract
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // get the current status of the contract
    function getOperationalStatus() public view returns(bool){
        return locked;
    }

    // fallback function to handle the ether transfer
    fallback () external payable {

    }

    receive() external payable {
        
    }
}