// SPDX-License-Identifier: MIT
// TODO - remove
// usd/usdt aggr. addr. - 0x92C09849638959196E976289418e5973CC96d645
// usd/matic aggr. addr. - 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AggregatorRate{
    
    AggregatorV3Interface internal priceFeed;
    string rateString;
    address public immutable admin;
    bool private active = true;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not Authorized!");
        _;
    }
    
    constructor(string memory assetOne, string memory assetTwo, address aggregatorAddress) {
        require(aggregatorAddress != address(0));
        priceFeed = AggregatorV3Interface(
            aggregatorAddress
        );
        rateString = string.concat(assetOne,"/",assetTwo); 
        admin = msg.sender;
    }

    function activate() public onlyAdmin{
        require(!active, "Already activated!");
        active = false;
    }

    function deactivate() public onlyAdmin{
        require(active, "Already deactivated!");
        active = true;
    }

    function changeAggregatorAddress(string memory assetOne, string memory assetTwo, address aggregatorAddress) public onlyAdmin{
        require(aggregatorAddress != address(0));
        priceFeed = AggregatorV3Interface(
            aggregatorAddress

        );
        // USD/USDT
        rateString = string.concat(assetOne,"/",assetTwo);
    }

    function getLatestRate() public view returns (int256, uint256, string memory, uint256) {
        if (!active){
            return(0,0,"Not active!",0);
        }
        (,int256 price,,uint256 date,) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (price, decimals, rateString, date);
    }
}
