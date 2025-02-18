// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Token is IERC20, IERC20Metadata {}

/**
 * A token holder contract that will allow the owner to extract the
 * tokens after a given release time.
 **/

contract PresaleVestingWallet is Ownable {
    using SafeERC20 for Token;

    // ERC20 basic token contract being held
    Token private immutable _token;
    // Wallet to receive the tokens
    address private immutable _newOwner;

    uint256 private immutable _releaseDate;


    /**
     *  Deploys a time-lock instance that is able to hold the token specified, and will only release it to
     * `owner` when {release} is invoked after `releaseDate`.
     *  The release date is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(Token token_, address newOwner, uint256 releaseDate) {
        require(releaseDate > block.timestamp, "Release date cant be lesser than curent block timestamp");
        require(newOwner != address(0), "Invalid owner address.");
        _token = token_;
        _newOwner = newOwner;
        _releaseDate = releaseDate;
        // Sets the owner of the contract!
        transferOwnership(newOwner);

    }
    modifier onlyAfterTimestamp() {
        require(_releaseDate <= timeNow(), "Claim unavailable before release date");
        _;
    }

    modifier requireNonEmptyBalance() {
        require(currentBalance() > 0, "Vesting wallet is empty!");
        _;
    }

    event TokensReleased(address beneficiary, uint256 amount);

    /**
     * Returns the token being held.
     */
    function token() public view returns (Token) {
        return _token;
    }

    /** Returns current block timestamp**/

    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }
    /**
     * Returns the symbol of the token being held.
     */
    function symbol() external view returns (string memory) {
        return _token.symbol();
    }

    /**
     * Returns the decimal of the token being held.
     */
    function decimals() external view returns (uint256) {
        return _token.decimals();
    }

    /**
     * Returns all tokens held in contract.
     */
    function currentBalance() public view returns (uint256){
        return token().balanceOf(address(this));
    }

    function getReleaseDate() public view returns (uint256){
        return _releaseDate;
    }


    /**
     * Checks if there are released payments for a beneficiary and any transfers the tokens to the beneficiary.
     * Can be called by Owner of the contract or the beneficiary.
     */
    function release() external onlyOwner onlyAfterTimestamp requireNonEmptyBalance {
        uint256 balance = currentBalance();
        token().safeTransfer(msg.sender, balance);
        emit TokensReleased(msg.sender, balance);
    }

    /**
    * Renounce ownership not possible with this smart contract.
    */
    function renounceOwnership() public onlyOwner view override (Ownable) {
        revert("This contract(wallet) doesn't support renouncing of ownership");
    }
}