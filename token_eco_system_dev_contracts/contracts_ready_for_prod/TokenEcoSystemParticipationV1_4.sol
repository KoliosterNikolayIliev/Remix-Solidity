// SPDX-License-Identifier: MIT

/**
* How to deploy:
* Only this contract must be validated.
* 1. Deploy TokenEcosystemParticipationContract.
* 2. Deploy AggregatorRate contract if relevant.
* 3. Deploy PoolRate contract if relevant.
* 4. AddPoolFeed in TokenEcosystemParticipationContract if relevant.
* 5. AddAggregatorFeed in TokenEcosystemParticipationContract if relevant.
* 6. Participant must activate the contract.
* 7. Participant/Owner must give allowance to TokenEcosystemParticipationContract.
* 8. Participant/Owner must charge the contract with tokens.
 */


// Charging:

// The contract is charged with tokens (token = ERC20BurnableInterface(_acceptedTokens);) via chargeContract function:
// Then the tokens are converted according USDT-token rate(pool or V3 Aggregator) and is divided by the modulator (default modulator value=2)
// The resulting points can be consumed by the owner
// The tokens are burned

// Consume points:

// When tokens are minted to end users, the owner is consuming the points of the contract according to the current USDT-token rate.


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AggregatorConsumerInterface {
    function getLatestRate()
    external
    returns (
        uint256,
        uint256,
        string memory,
        uint256 date
    );
}

interface PoolConsumerInterface {
    function poolRate()
    external
    returns (
        uint256,
        uint256,
        string memory,
        uint256 date
    );
}

interface ERC20BurnableInterface is IERC20, IERC20Metadata {
    function burn(uint256 amount) external;
}

contract TokenEcoSystemParticipation is Pausable, Ownable {
    using SafeERC20 for ERC20BurnableInterface;

    // Constants
    ERC20BurnableInterface private immutable token;
    string private name_;

    // State variables
    bool private contractActivated = true;
    address private acceptedSenderAddress;
    bool private poolRateFeed = true;
    uint256 private totalBurned = 0;
    uint256 private totalConverted = 0;
    uint256 private pointsBalance = 0;
    uint256 private modulator = 2;

    AggregatorConsumerInterface aggregatorConsumer;
    PoolConsumerInterface poolConsumer;

    // Events
    event ChargeContract(
        uint256 chargeRate,
        uint256 chargeRatedecimals,
        uint256 chargeRateDate,
        string chargeRateString,
        uint256 chargedPoints,
        uint256 burnedTokens,
        uint256 indexed chargeDate
    );


    event ConsumePoints(
        uint256 indexed timestamp,
        address participant,
        uint256 value,
        bytes32 txHash
    );


    event ModulatorChanged(uint256 indexed timestamp, uint256 newValue);

    event NewAcceptedSender(uint256 indexed timestamp, address newAcceptedSender);

    event GetRate(uint256 rate, uint256 decimals, string rateString, uint256 date, string feed);

    // Modifiers
    modifier onlyAuthorized() {
        require(msg.sender == acceptedSenderAddress, "Not Authorized!");
        _;
    }

    modifier activated() {
        require(isActive(), "Not activated!");
        _;
    }

    modifier onlyOwnerOrAuthorized() {
        require(msg.sender != address(0));
        require(
            (msg.sender == acceptedSenderAddress || msg.sender == owner()),
            "Only Owner or Authorized participator can access this operation!"
        );
        _;
    }

    // Constructor
    constructor(
        string memory _name, 
        address _acceptedTokens, 
        address _acceptedSenderAddress, 
        address _poolConsumerInterfaceAddress, 
        address _aggregatorConsumerInterfaceAddress) {
        require(_acceptedSenderAddress != address(0),"Can't be zero address.");
        require(_acceptedTokens != address(0), "Can't be zero address.");
        require(bytes(_name).length == 3, "Name length must be 3.");
        name_=_name;
        acceptedSenderAddress = _acceptedSenderAddress;
        token = ERC20BurnableInterface(_acceptedTokens);
        //@dev pass 0x0000000000000000000000000000000000000000 if price feed will be configured later.
        poolConsumer = PoolConsumerInterface(_poolConsumerInterfaceAddress);
        aggregatorConsumer = AggregatorConsumerInterface(_aggregatorConsumerInterfaceAddress);

    }



    // Public functions

    // Short name of the participant
    function name() public view returns (string memory){
        return name_;
    }

    // Activates the contract by participator
    function activate() public onlyAuthorized whenNotPaused {
        require(!isActive(), "Already activated!");
        contractActivated=true;
    }

    // Deactivates the contract by participator
    function deactivate() public activated onlyAuthorized whenNotPaused {
       contractActivated=false;
    }

    // check if contract is active
    function isActive() public view whenNotPaused returns( bool ){
        return contractActivated;
    }

    // Participator can change the charging address
    function changeAcceptedSenderAddress(address newAcceptedSender)
    public
    activated
    onlyAuthorized
    whenNotPaused
    {
        require(newAcceptedSender != address(0), "Can't be zero address.");
        require(newAcceptedSender != acceptedSenderAddress, "Can't change, address is the same.");
        emit NewAcceptedSender(block.timestamp ,newAcceptedSender);
        acceptedSenderAddress = newAcceptedSender;
    }

    // Owner can stop (pause) the contract
    function stop() public whenNotPaused onlyOwner {
        _pause();
    }

    // Owner can resume (unpause) the contract
    function resume() public whenPaused onlyOwner {
        _unpause();
    }

    function setModulator(uint256 value) public whenNotPaused onlyOwner {
        require(value > 0, "Input must be greater than zero!");
        require(value < 10, "Input must be a single digit (0-9)");
        require(value != modulator, "Input value is the same like existing!");
        emit ModulatorChanged(block.timestamp, value);
        modulator = value;
    }

    function viewModulator() whenNotPaused public view returns (uint256){
        return modulator;
    }

    // Adds rateFeed from ChainLink V3 Aggregator
    function addNewAggregatorPriceFeed(address consumerInterfaceAddress)
    public
    onlyOwner
    whenNotPaused
    activated
    {
        require(consumerInterfaceAddress != address(0), "Can't be zero address.");
        aggregatorConsumer = AggregatorConsumerInterface(
            consumerInterfaceAddress
        );
    }

    // Adds rateFeed from Existing liquidity pool pair (Token1/Token2)
    function addNewPoolRateFeed(address consumerInterfaceAddress)
    public
    onlyOwner
    whenNotPaused
    activated
    {
        require(consumerInterfaceAddress != address(0));
        poolConsumer = PoolConsumerInterface(consumerInterfaceAddress);
    }

    // Switches the rateFeed in use AggregatorFeedRate/PoolFeedRate

    function changeRateFeed() public onlyOwner activated whenNotPaused{
        if (poolRateFeed) {
            require(
                poolRateFeed && (address(aggregatorConsumer) != address(0)),
                "AggregatorConsumer is not initialized!"
            );
        } else {
            require(
                !poolRateFeed && (address(poolConsumer) != address(0)),
                "PoolConsumer is not initialized!"
            );
        }
        poolRateFeed = !poolRateFeed;
    }

    // Returns currently active RateFeed
    function currentRateFeed() whenNotPaused activated public view returns (string memory, address) {
        string memory feed = currentFeed();
        if (poolRateFeed) {
            return (feed, address(poolConsumer));
        } else {
            return (feed, address(aggregatorConsumer));
        }
    }

    // Calculates Token amount from points based on rate and is only for informative purposes.
    // TODO - dev remove in production
    function calculateAmount(
        uint256 points,
        uint256 rate,
        uint256 decimals
    ) public view onlyOwner whenNotPaused returns (uint256) {
        require(
            rate > 0 && points > 0 && decimals > 0,
            "Rate, points and decimals must be greater than zero!"
        );
        return (points * modulator  * 10 ** decimals)/ rate;
    }

    function checkAllowance() public onlyOwnerOrAuthorized view returns (uint256){
        return token.allowance(msg.sender, address(this));
    }

    // Returns balance of tokens which are accidentally sent to the contract not using the chargeContract function
    function balanceOf() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Returns balance of other tokens which are accidentally sent to the contract not using the chargeContract function
    function balanceOfToken(address tokenAddress)
    public
    view
    onlyOwner
    returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // Returns info about the native token of the contract
    function getTokenInfo()
    public
    view
    activated
    onlyOwnerOrAuthorized
    whenNotPaused
    returns (address, string memory)
    {
        return (address(token), token.symbol());
    }

    // Owner can return tokens sent to the contract my mistake not using the chargeContract function
    function transferOfToken(
        address tokenAddress,
        address receiver,
        uint256 amount
    ) public onlyOwner returns (bool) {
        require(balanceOfToken(tokenAddress) >= amount, "Not enough balance!");
        return IERC20(tokenAddress).transfer(receiver, amount);
    }

    // The participant charges the contract with Tokens
    // The tokens are burned instantaneously and points are created
    function chargeContract(uint256 amount)
    public
    whenNotPaused
    activated
    onlyOwnerOrAuthorized
    returns (bool)
    {
        require(amount > 0, "No charge amount!");
        require(
            checkAllowance() >= amount,
            string.concat("Check the ", token.symbol(), " token ", "allowance!")
        );

        (
            uint256 rate,
            uint256 decimals,
            string memory chargeRateString,
            uint256 chargeRateDate
        ) = getRate();
        require(rate > 0 && decimals > 0 && chargeRateDate > 0, "Rate error!");
        uint256 points = calculatePoints(amount, rate, decimals);
        pointsBalance += points;
        totalConverted += points;
        totalBurned += amount;
        uint256 chargeTime = block.timestamp;
        emit ChargeContract(
            rate,
            decimals,
            chargeRateDate,
            chargeRateString,
            points,
            amount,
            chargeTime
        );
        token.safeTransferFrom(msg.sender, address(this), amount);
        burnIncomingTokens(amount);
        return true;
    }

    // Called on every withdraw initiated by contract owner
    function consumePoints(uint256 value, bytes32 txHash) public onlyOwner activated whenNotPaused {
        require(
            value <= pointsBalance, "Not enough points. The contract must be charged with more tokens"
        );
        require(value > 0, "Withdraw value must be greater than 0!");
        emit ConsumePoints(block.timestamp, acceptedSenderAddress, value, txHash);
        pointsBalance -= value;
    }

    // Returns total amount of burned tokens since contract activation
    function getTotalBurnedTokens()
    public
    view
    activated
    onlyOwnerOrAuthorized
    returns (uint256)
    {
        return totalBurned;
    }

    // Returns total amount of points generated from token burning since contract activation
    function getTotalPointsGenerated()
    public
    view
    activated
    onlyOwnerOrAuthorized
    returns (uint256)
    {
        return totalConverted;
    }

    // Returns the available points
    function getPointsBalance()
    public
    view
    activated
    onlyOwnerOrAuthorized
    returns (uint256)
    {
        return pointsBalance;
    }

    // Returns initial address of the participator by which the contract was activated and current participator address
    function getAcceptedSenderAddress()
    public
    view
    activated
    whenNotPaused
    returns (address)
    {
        return acceptedSenderAddress;
    }

    // Private functions

    // Returns the current rate of the native token depending on the rateFeed
    function getRate()
    private
    returns (
        uint256,
        uint256,
        string memory,
        uint256
    )
    {
        if (poolRateFeed) {
            require(
                poolRateFeed && (address(poolConsumer) != address(0)),
                "PoolConsumer is not initialized!"
            );
        } else {
            require(
                !poolRateFeed && (address(aggregatorConsumer) != address(0)),
                "AggregatorConsumer is not initialized!"
            );
        }

        (
            uint256 rate,
            uint256 decimals,
            string memory rateString,
            uint256 date
        ) = !poolRateFeed
            ? aggregatorConsumer.getLatestRate()
            : poolConsumer.poolRate();
        emit GetRate(rate, decimals, rateString, date, currentFeed());
        return (rate, decimals, rateString, date);
    }

    // Calculates the points to be charged after token burning
    function calculatePoints(
        uint256 amount,
        uint256 rate,
        uint256 decimals
    ) private view returns (uint256) {
        return ((amount * rate) / modulator ) / 10 ** decimals;
    }

    function currentFeed() private view returns (string memory){
        string memory result;
        poolRateFeed ? result = "Pool" : result = "AggregatorV3";
        return result;
    }
    // Burns the native tokens on contract charging
    function burnIncomingTokens(uint256 amount) private returns (bool) {
        require(amount > 0, "No tokens to be burned!");
        uint256 balance = balanceOf();
        token.burn(amount);
        require(balanceOf() == balance - amount, "transaction reverted burn unsuccessful!");
        return true;
    }
}

// TODO - remove
// dummy test_net - 0x29c11c0Ea107F5E00Bc71C68fc3598Fa20a2ee9c
// rate pool test_net - 0xeFEABf68B08f94EEc45DC7b64a80f5280DAB7E56
// rate aggr test_net - 0x7ABbC9D596e7e49d2754f9c823f545f8056Feae8