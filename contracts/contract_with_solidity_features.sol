// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;



error Custom__Error(string message);
error YourError(bytes response);

enum State { Pending, Active, Inactive }

contract Tester {

    uint8 private constant SAMPLE_SMAL_UNIT = 128;
    State public currentState;
    struct User{
        address wallet;
        uint256 amount; 
    }

    User [] private users;
    
    constructor(){
        currentState = State.Pending;
    }

    

    event addressAdded(address user, uint256 value);

    function RaiseError() public pure {
        revert Custom__Error("Pesho e pedal!!!");
    }

    function testCaldata(string calldata message) public pure returns (string memory){
        string memory a = "123";
        // return  string.concat(message, a);
        string memory newMessage = string.concat(message, a);
        return newMessage;
    }

    function simpleSubstraction(int256 a, int256 b) public pure returns (int){
        bool success = a>0;
        if (!success) { revert YourError("Ne staa"); }
        return a-b; 
    }

    function simpleSubstractionWithOtherErrorHandling(int256 a, int256 b) public pure returns (int){
        bool success = a>0;
        require(success, "ne staaa");
        return a-b; 
    }

    function addUser(address _addr, uint256 _amount) public {
        User memory newUser = User(_addr, _amount);
        users.push(newUser);
        emit addressAdded(_addr, _amount);
    }

    function getUser(address _addr) public view returns(uint256){
        uint256 amount = 0;
        for (uint256 i; i<users.length; i++) 
        {
            if (_addr == users[i].wallet) {
                amount = users[i].amount;
                break; 
            }
        }
        return amount;
    }

    function testFuncReturningMoreThanOneValue() external pure returns (uint256, string memory){
        return (12, "pesho");
    }    

    function testReturnsTupleWhichIsNotPossibleInSolidity() external pure returns (uint256, uint256){
        return (1,2);
    }

    function activate() external {
        currentState = State.Active;
    }

    function deactivate() external {
        currentState = State.Inactive;
    }


    

}