// // SPDX-License-Identifier: UNLICENSED

// // Short description
// // The contract must be responsible for and have following properties:
// // 1. Keep record of the burned tokens of a customer for every refill
// // 2. Keeps record for the rate on every refill
// // 3. The contract must have user (one that can charge and withdraw funds)
// // 4. Note: Should the contract be payable and keep other funds?
// // 5. The user must have operator (wallet with private key on the server) - will execute all automatiic activities
// //    - keep bulk mint record
// //    - reset bulk mint record
// //    - burn tokens maybe allowance will be needed
// // 6. The contract must have Admin for special cases:
// //    - change the operator
// //    - manual burn after allowance?
// //    - manual reset counter?
// //    - block tokens ???
// //    - manual transfer of tokens
// // 7. GAS efficiency is a must!
// // 8. Pausable

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// interface Token is IERC20, IERC20Metadata {}

// contract autoBurningContract is Ownable {
//     using SafeERC20 for Token;

//     // ERC20 basic token contract being held
//     Token private immutable _token;
//     // Wallet to receive the tokens
//     address private immutable _newOwner;

//     uint256 private immutable _releaseDate;

//     /**
//      *  Deploys a time-lock instance that is able to hold the token specified, and will only release it to
//      * `owner` when {release} is invoked after `releaseDate`.
//      *  The release date is specified as a Unix timestamp
//      * (in seconds).
//      */
//     constructor(
//         Token token_,
//         address newOwner,
//         uint256 releaseDate
//     ) {
//         require(
//             releaseDate > block.timestamp,
//             "Release date cant be lesser than curent block timestamp"
//         );
//         require(newOwner != address(0), "Invalid owner address.");
//         _token = token_;
//         _newOwner = newOwner;
//         _releaseDate = releaseDate;
//         // Sets the owner of the contract!
//         transferOwnership(newOwner);
//     }

//     modifier onlyAfterTimestamp() {
//         require(
//             _releaseDate <= timeNow(),
//             "Claim unavailable before release date"
//         );
//         _;
//     }

//     modifier requireNonEmptyBalance() {
//         require(currentBalance() > 0, "Vesting wallet is empty!");
//         _;
//     }

//     event TokensReleased(address beneficiary, uint256 amount);

//     /**
//      * Returns the token being held.
//      */
//     function token() public view returns (Token) {
//         return _token;
//     }

//     /** Returns current block timestamp**/

//     function timeNow() public view returns (uint256) {
//         return block.timestamp;
//     }

//     /**
//      * Returns the symbol of the token being held.
//      */
//     function symbol() external view returns (string memory) {
//         return _token.symbol();
//     }

//     /**
//      * Returns the decimal of the token being held.
//      */
//     function decimals() external view returns (uint256) {
//         return _token.decimals();
//     }

//     /**
//      * Returns all tokens held in contract.
//      */
//     function currentBalance() public view returns (uint256) {
//         return token().balanceOf(address(this));
//     }

//     function getReleaseDate() public view returns (uint256) {
//         return _releaseDate;
//     }

//     /**
//      * Checks if there are released payments for a beneficiary and any transfers the tokens to the beneficiary.
//      * Can be called by Owner of the contract or the beneficiary.
//      */
//     function release()
//         external
//         onlyOwner
//         onlyAfterTimestamp
//         requireNonEmptyBalance
//     {
//         uint256 balance = currentBalance();
//         token().safeTransfer(msg.sender, balance);
//         emit TokensReleased(msg.sender, balance);
//     }

//     /**
//      * Renounce ownership not possible with this smart contract.
//      */
//     function renounceOwnership() public view override(Ownable) onlyOwner {
//         revert("This contract(wallet) doesn't support renouncing of ownership");
//     }



//     //  




//     function withdraw() public {}

//     // must take into acount burn variable
//     function burnTokens() public {}

//     // updates the local burn variable
//     function updateToBeBurned() public {}

//     function balance() public {}
// }


pragma solidity ^0.8.0;

// Interface for the deployed contract
interface PriceConsumerV3Interface {
    function getLatestPrice() external returns (uint256);
}

contract CallingContract {
    PriceConsumerV3Interface priceConsumerV3;
    uint256 cur_price;

    event price(uint256);


    function add_price_feed (address _priceConsumerV3InterfaceAddress) public {
        priceConsumerV3 = PriceConsumerV3Interface(_priceConsumerV3InterfaceAddress);
    }

    function getAddressOfprice() public view returns(address){
        return address(priceConsumerV3);
    }

    function getPrice() private returns(uint256){
        // Call a function of the deployed contract
        return priceConsumerV3.getLatestPrice();
        
    }
    function getCurPrice() public 
     returns(uint256){
        cur_price = getPrice();
        emit price(cur_price);
        return cur_price;
    }
}