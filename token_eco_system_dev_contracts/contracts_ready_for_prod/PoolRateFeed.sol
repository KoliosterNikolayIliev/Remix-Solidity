// SPDX-License-Identifier: MIT
// TODO - remove pool address  0xd0C3c6f5660761B87e884f3280fc950D61bF45d9

pragma solidity ^0.8.0;

interface PoolInterface {
    function getReserves()
    external
    returns (
        uint112,
        uint112,
        uint32
    );

    function token0() external returns (address);

    function token1() external returns (address);
}

interface DecimalsInterface {
    function decimals() external returns (uint8);

    function name() external returns (string calldata);
}

contract RateFromPool {

    PoolInterface poolConsumer;
    DecimalsInterface decimalsConsumerOne;
    DecimalsInterface decimalsConsumerTwo;
    address public immutable admin;
    bool private active = true;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not Authorized!");
        _;
    }

    constructor (address poolConsumerInterfaceAddress){
        require(poolConsumerInterfaceAddress != address(0));
        admin = msg.sender;
        poolConsumer = PoolInterface(
            poolConsumerInterfaceAddress
        );
        
    }

    function activate() public onlyAdmin{
        require(!active, "Already activated!");
        active = false;
    }

    function deactivate() public onlyAdmin{
        require(active, "Already deactivated!");
        active = true;
    }

    function addNewPoolFeed(address poolConsumerInterfaceAddress)public onlyAdmin{
        poolConsumer = PoolInterface(
            poolConsumerInterfaceAddress
        );
    }

    function poolRate() public returns(uint256, uint256, string memory, uint256) {
        if (!active){
            return(0,0,"Not active!",0);
        }
        address tokenOneAddress = poolConsumer.token0();
        address tokenTwoAddress = poolConsumer.token1();
        decimalsConsumerOne = DecimalsInterface(tokenOneAddress);
        decimalsConsumerTwo = DecimalsInterface(tokenTwoAddress);
        uint256 decimalsOne = decimalsConsumerOne.decimals();
        uint256 decimalsTwo = decimalsConsumerTwo.decimals();
        string memory nameOne = decimalsConsumerOne.name();
        string memory nameTwo = decimalsConsumerTwo.name();
        (uint256 tokenOne, uint256 tokenTwo, uint32 date) = poolConsumer.getReserves();


        return calculatePoolRate(
            tokenOne,
            decimalsOne,
            nameOne,
            tokenTwo,
            decimalsTwo,
            nameTwo,
            date
        );

    }

    function calculatePoolRate(

        uint256 tokenOne,
        uint256 decimalOne,
        string memory tokenOneName,
        uint256 tokenTwo,
        uint256 decimalTwo,
        string memory tokenTwoName,
        uint32 date

    ) private pure returns (uint256, uint256, string memory, uint256) {
        require(bytes(tokenOneName).length > 0 && bytes(tokenTwoName).length > 0, "Missing input for token name!");
        require(decimalOne <= 18 && decimalTwo <= 18, "Decimals should be less than or equal to 18");
        require(decimalOne > 0 && decimalTwo > 0, "Decimals should be greater than 0");
        require(tokenOne > 0 && tokenTwo > 0, "Token values should be greater than 0");

        if (decimalOne > decimalTwo) {
            tokenTwo = tokenTwo * 10**(decimalOne - decimalTwo);
        } else {
            tokenOne = tokenOne * 10**(decimalTwo - decimalOne);
        }
        return (tokenTwo*10**8 / tokenOne, 8, string.concat(tokenTwoName, "/", tokenOneName), date);
    }
}
