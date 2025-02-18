// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SampleERC20Test {

    string private name_;

    constructor(string memory _name){
        require(bytes(_name).length == 3, "Name length must be 3.");
        name_=_name;
    }
    
     function name() public view returns (string memory){
        return name_;
    }
}