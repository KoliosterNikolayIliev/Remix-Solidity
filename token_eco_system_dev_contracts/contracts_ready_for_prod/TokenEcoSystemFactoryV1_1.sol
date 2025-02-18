// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenEcoSystemParticipationV1_4_prod.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenEcoSystemParticipationFactory is Ownable{
    // Array to keep track of all deployed instances

    address[] private deployedContracts;

    event ContractCreated(address indexed newContract);

    // Deploy contract instances
    function createTokenEcoSystemParticipation(
        string memory _name, 
        address _acceptedTokens,
        address _acceptedSenderAddress,
        address _poolConsumerInterfaceAddress,
        address _aggregatorConsumerInterfaceAddress)
        onlyOwner public {

        TokenEcoSystemParticipation newContract = new TokenEcoSystemParticipation(
            _name, _acceptedTokens,
            _acceptedSenderAddress,
            _poolConsumerInterfaceAddress,
            _aggregatorConsumerInterfaceAddress);

        newContract.transferOwnership(msg.sender);
        deployedContracts.push(address(newContract));

        emit ContractCreated(address(newContract));
    }

    // Get the list of all deployed contracts
    function getDeployedContracts() public view returns (address[] memory) {
        return deployedContracts;
    }
}