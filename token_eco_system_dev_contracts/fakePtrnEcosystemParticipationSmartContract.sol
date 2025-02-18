// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface AgregatorConsumerInterface {
    function getLatestRate() external returns (uint256, uint256, string memory, uint256 date);
}

interface PoolConsumerInterface {
    function PoolRate() external returns (uint256, uint256, string memory, uint256 date);
}

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

contract PtrnEcoSystemParticipation is Pausable, Ownable {

    
    address private immutable ACCEPTED_TOKEN_ADDRESS;
    // there must be change of sender function;
    address private immutable ACCEPTED_SENDER_ADDRESS;

    bool poolRateFeed = true;
    
    // struct LastCharge{
    //     uint256 chargedPTRN;
    //     uint256 ptrnToPoints;
    //     uint256 rate;
    //     uint256 rateTimestamp;
    //     string rateFrom;
         
    // }


    AgregatorConsumerInterface agregatorConsumer;
    PoolConsumerInterface poolConsumer;

    uint256 public burned=0;

    struct RateData {
        uint256 tokenRate;
        uint256 decimals;
        string tokenRateString;
        uint256 date;
        string feed;
    } 

    RateData private rateData;

    uint256 public availableToWithdraw = 0;
    uint256 public daily_withdraw = 0;


    constructor(address _acceptedTokens, address _acceptedSenderAddress){
        ACCEPTED_TOKEN_ADDRESS = _acceptedTokens;
        ACCEPTED_SENDER_ADDRESS = _acceptedSenderAddress;
    }


    // check if needed 
    // modifier isAgregatorConsumerInitialized() {
    //     require(address(agregatorConsumer) != address(0), "AgregatorConsumer is not initialized");
    //     _;
    // }

    // check if needed 
    // modifier isPoolConsumerInitialized() {
    //     require(address(poolConsumer) != address(0), "PoolConsumer is not initialized");
    //     _;
    // }



    function changeRateFeed() public onlyOwner{

        poolRateFeed = !poolRateFeed;
    } 

    function currentRateFeed() public view returns (string memory){
        string memory result;
        poolRateFeed ? result = "Pool": result = "AggregatorV3";
        return result;
    }

   

    function addAgregatorPriceFeed(address _ConsumerInterfaceAddress) public onlyOwner {
        agregatorConsumer = AgregatorConsumerInterface(_ConsumerInterfaceAddress);
    }

    function addPoolRateFeed(address _ConsumerInterfaceAddress) public onlyOwner{
        poolConsumer = PoolConsumerInterface(_ConsumerInterfaceAddress);
    }

    // For prod
    // function setRate() public returns (bool) {
    //     //require(poolRateFeed && (address(poolConsumer) != address(0)), "PoolConsumer is not initialized");
    //     //require(poolRateFeed && (address(agregatorConsumer) != address(0)), "AgregatorConsumer is not initialized");
    //     (uint256 rate, uint256 decimals, string memory rateString, uint256 date) = 
    //         !poolRateFeed ? agregatorConsumer.getLatestRate() : poolConsumer.PoolRate();
        
    //     rateData.tokenRate = rate;
    //     rateData.decimals = decimals;
    //     rateData.tokenRateString = rateString;
    //     rateData.date = date;
    //     rateData.feed = poolRateFeed ? "Pool" : "AgregatorV3";

    //     return true;
    // }


    // JUST FOR TESTING
    function setRate() public returns (bool) {
    //require(poolRateFeed && (address(poolConsumer) != address(0)), "PoolConsumer is not initialized");
    //require(poolRateFeed && (address(agregatorConsumer) != address(0)), "AgregatorConsumer is not initialized");
    // (uint256 rate, uint256 decimals, string memory rateString, uint256 date) = 
    //     !poolRateFeed ? agregatorConsumer.getLatestRate() : poolConsumer.PoolRate();
    
    rateData.tokenRate = 11111111;
    rateData.decimals = 8;
    rateData.tokenRateString = "fakeUSDT/DummyPTRN";
    rateData.date = 1700135082;
    rateData.feed = poolRateFeed ? "Pool" : "AgregatorV3";

    return true;
    }


    function getRate() public view returns (uint256, uint256, string memory, uint256, string memory) {
        return (rateData.tokenRate, rateData.decimals, rateData.tokenRateString, rateData.date, rateData.feed);
    }

    function calculatePoints(uint256 amount, uint256 rate, uint256 decimals) public pure returns (uint256){
        uint256 resultIn26Decimals = amount * rate;
        return resultIn26Decimals / 10**decimals;

    }

    function calculateAmount(uint256 points, uint256 rate, uint256 _decimals) public pure returns (uint256){
        require(rate > 0, "Rate must be greater than zero");
        uint256 amountIn26Decimals = points * 10**_decimals;
        return amountIn26Decimals / rate;
    }


    // struct with (entered tokens, generated points , course(rate, feed, timestamp, ) )
    // This is the resricted receive function
    // need to add the burning logi here
    function chargeContract(uint256 amount) public returns (bool){
        require(msg.sender == ACCEPTED_SENDER_ADDRESS, "Sender not authorized");
        // save the value and ptrns and usdt rate
        // need allownce
        //require(IERC20(ACCEPTED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount), "Transfer failed only PTRN tokens accepted!");
        require(msg.sender == ACCEPTED_SENDER_ADDRESS, "Sender not authorized");
        IERC20 token = IERC20(ACCEPTED_TOKEN_ADDRESS);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        // set the rate!!! 
        setRate();
        (uint256 rate, uint256 decimals, , ,) = getRate();
        burnIncomingTokens(amount);
        availableToWithdraw += calculatePoints(amount, rate, decimals);
        // calculatePoints - take into acount if token1>token2 or the opposite to know how the rate is calculated!!!
        // 
        return(true);
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(ACCEPTED_TOKEN_ADDRESS).balanceOf(address(this));
    }

    function withdraw(uint256 value) onlyOwner public{
        require(value<= availableToWithdraw-daily_withdraw, "Not enough points. The contract must be charged with more PTRN");
        daily_withdraw+=value;
    }

    function dailyReward() onlyOwner public{
        // maybe transaction value must be written
        availableToWithdraw-=daily_withdraw;
        daily_withdraw=0;
    }  
    
    // check balance of tokens sent by mistake
    function balanceOfToken(address tokenAddress) public onlyOwner view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    // need check balance and other validation
    function transferOfToken(address tokenAddress, address receiver, uint256 amount) public onlyOwner returns (bool){
        require(balanceOfToken(tokenAddress)>=amount, "Not enough balance!");
        return IERC20(tokenAddress).transfer(receiver, amount);
    }

    function burnIncomingTokens(uint256 amount) private returns (bool) {
        
        require(amount>0, "No tokens to be burned!");
        IERC20Burnable token = IERC20Burnable(ACCEPTED_TOKEN_ADDRESS);
        token.burn(amount);
        burned+=amount;
    return true;
    }


}   

//poolrate - 0x8258CEF9E10Fe6160c209d44BCDb5e1a642699F1
// fake agr - 0x96bFec911003979AF3e4a1975647F98229A1087C
// fakeptrn - 0x29c11c0Ea107F5E00Bc71C68fc3598Fa20a2ee9c