// SPDX-License-Identifier: MIT

// contract Dummy123 {
//     function returnZeroaddress() public pure returns(bool){
//         return address(0)==0x0000000000000000000000000000000000000000;
//     }
// }

pragma solidity ^0.8.0;

contract Dummy123 {
    uint256[4] private lst2;
    address[] private lst = [
        0x2C46c2557ff6B55Cb10330390D31A8b574cE5Ed0,
        0x2C46c2557ff6B55Cb10330390D31A8b574cE5Ed0,
        0x2C46c2557ff6B55Cb10330390D31A8b574cE5Ed0,
        0x2C46c2557ff6B55Cb10330390D31A8b574cE5Ed0
        ];
    uint256[] private idxf;

    function kur() public view returns (uint256[] memory){
        return idxf;
    }
    

    mapping(address => uint256[4][]) public _beneficiaries;
    address beneficiary_ = 0x2C46c2557ff6B55Cb10330390D31A8b574cE5Ed0;
    function add() public{
        for (uint256 i=0; i<lst.length;i++)
        _beneficiaries[lst[i]].push([1, 2, 0, 0]);
    }
    
    function getben(address ben) public view returns (uint256[4][] memory){
        return _beneficiaries[ben]; 
    }

    function orderedRemoveFromBeneficiaryList(uint index, address[] storage modified) internal returns(address[] memory){
            
        for (uint i = index; i < modified.length - 1; i++) {
            modified[i] = modified[i + 1];
        }
        modified.pop();
        return modified;
        
    }

    function getlist() public view returns(address[] memory){
        return lst;
    }

    function modify(uint index) public {
        lst = orderedRemoveFromBeneficiaryList(index, lst);
    }
    function getlen() public view returns(uint256){
        return lst.length;
    }

       function approvePayment(address ben, uint256[] calldata indexes) public {
        require(indexes.length > 0,"No selected payments for approval!");
        require(_beneficiaries[ben].length > 0, "Beneficiary not existing!");
        require(_beneficiaries[ben].length >= indexes.length, "Wrong payment data!");
        
        for (uint256 i = 0; i < indexes.length; i++) {
            require(indexes[i] < _beneficiaries[ben].length, "Index error, no such payment!");
            require(_beneficiaries[ben][indexes[i]][3]==0, "Payment already approved!");
            
            if(indexes[i]>0){
                require(_beneficiaries[ben][indexes[i]-1][3] == 1, "Can't approve next payment before the previous one!");
            }
            _beneficiaries[ben][indexes[i]][3] = 1;
        }
    }
}