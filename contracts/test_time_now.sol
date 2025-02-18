pragma solidity ^0.8.0;
contract testTimeNow{
 

    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }


    function checkTimediff(uint256 timestamp) public view returns (bool){
        return timestamp>timeNow();
        
    }

    function stringCompare(string calldata a)public pure returns(bool){
        return keccak256(abi.encodePacked((""))) != keccak256(abi.encodePacked((a)));
    }

    function checkBool(bool a) public pure returns(bool){
        return a==false;
    }

    function stringLength(string calldata a) public pure returns(uint256){
        return bytes(a).length;
    }

    function generateAddress(uint160 number) public pure returns (address){
        address a = address(number);
        return a;
    }
    function gasss() public view  returns (uint256){
        return tx.gasprice;
    }

}