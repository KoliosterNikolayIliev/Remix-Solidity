pragma solidity ^0.8.0;
contract itemRemoval{
    uint[] internal  firstArray = [1,2,3,4,5];
    uint[] internal  secondArr = [4,4,4,4,5];

    function getFirstArray(uint[] memory arr) private pure returns (uint[] memory){
        return arr;
    }

    function justGet() public view returns(uint[] memory){
        return getFirstArray(firstArray);
    } 

    function justGet2() public view returns(uint[] memory){
        return getFirstArray(secondArr);
    }

    function removeItem(uint i) public{
        delete firstArray[i];
    }


    function getLength() public view returns(uint){
        return firstArray.length;
    }


    function remove(uint index) public{
        firstArray[index] = firstArray[firstArray.length - 1];
        firstArray.pop();
    }


    function orderedArray(uint index) public{
        for(uint i = index; i < firstArray.length-1; i++){
        firstArray[i] = firstArray[i+1];      
        }
        firstArray.pop();
    }
}