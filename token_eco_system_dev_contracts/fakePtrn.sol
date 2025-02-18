//0x29c11c0Ea107F5E00Bc71C68fc3598Fa20a2ee9c - testnet
// 0xD6c665cbF8C2f55F702d47A09AB78ff821755648 - mainnet
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DummyPTRN is ERC20, ERC20Burnable, Pausable, Ownable {


    uint256 private immutable _cap;
    uint256 private _total_minted;
    //example service fee 100% = 100000000000000000000
    //example 1%= 1000000000000000000
    uint256 private _service_fee;
    // example _max_service_fee = 155000000000000000 (15.5%)
    uint256 private immutable _max_service_fee;
    uint256 private _single_mint_service_fee;
    uint256 private immutable _max_single_mint_service_fee;
    address private _fee_wallet;
    // Token distribution
    mapping(string => uint256) public currentDistribution;
    mapping(string => uint256) public distributionLimits;
    string public distributionList = "public_distribution,private_sale,initial_dex_offering,liquidity,marketing,team_and_advisors,partnerships,airdrop";


    constructor
    (
        address fee_wallet_) ERC20("DummyPTRN", "DPTRN"
    )

    {
        _cap = 300000000000000000000000000;
        _service_fee = 1000000000000000000;
        _max_service_fee = 5000000000000000000;
        _single_mint_service_fee = 1500000000000000000;
        _max_single_mint_service_fee = 5500000000000000000;
        _total_minted = 0;
        _fee_wallet = fee_wallet_;

        // distribution.
        currentDistribution["public_distribution"] = 0;
        currentDistribution["private_sale"] = 0;
        currentDistribution["initial_dex_offering"] = 0;
        currentDistribution["liquidity"] = 0;
        currentDistribution["marketing"] = 0;
        currentDistribution["team_and_advisors"] = 0;
        currentDistribution["partnerships"] = 0;
        currentDistribution["airdrop"] = 0;

        distributionLimits["public_distribution"] = 150000000000000000000000000;
        distributionLimits["private_sale"] = 27000000000000000000000000;
        distributionLimits["initial_dex_offering"] = 15000000000000000000000000;
        distributionLimits["liquidity"] = 30000000000000000000000000;
        distributionLimits["marketing"] = 30000000000000000000000000;
        distributionLimits["team_and_advisors"] = 36000000000000000000000000;
        distributionLimits["partnerships"] = 9000000000000000000000000;
        distributionLimits["airdrop"] = 3000000000000000000000000;
    }


    // Returns the maximum number of tokens available for minting.
    function cap() public view returns (uint256) {
        return _cap;
    }
    // Set another wallet for collecting fees.
    function changeFeeWallet(address wallet) public onlyOwner returns (address){
        _fee_wallet = wallet;
        return wallet;
    }

    // Returns the fee collector wallet.
    function feeWallet() public view returns (address){
        return _fee_wallet;
    }

    // Checking the cap before minting.
    function _mint(address account, uint256 amount) internal override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }


    // Freeze the contrant. Only owner can do it.
    function pause() public onlyOwner {
        _pause();
    }

    // Unfreeze the contract. Only owner can do it.
    function unpause() public onlyOwner {
        _unpause();
    }

    // Minting can be executed by owner only! Custom mint function. Mints acording to distribution.
    function mint(address account, uint256 amount, string calldata beneficiary) public onlyOwner {
        require(currentDistribution[beneficiary] + amount <= distributionLimits[beneficiary], "Cannot mint. Beneficiary limit exceeded!");
        _mint(account, amount);
        _total_minted += amount;
        currentDistribution[beneficiary] += amount;
    }

    // Returns what is available for minting according to distribution.
    function checkBeneficiaryLeftToMint(string calldata beneficiary) public view onlyOwner returns (uint256){
        uint256 result = distributionLimits[beneficiary] - currentDistribution[beneficiary];
        return result;
    }

    // Owner can change bulk mint fee.
    function setServiceFee(uint256 value) public onlyOwner returns (bool){
        require(value <= _max_service_fee, "Service fee can't be greater than max service fee!");
        _service_fee = value;

        return true;
    }

    // Owner can change single mint fee.
    function setSingleMintServiceFee(uint256 value) public onlyOwner returns (bool){
        require(value <= _max_single_mint_service_fee, "Single mint service fee can't be greater than max single mint service fee!");
        _single_mint_service_fee = value;

        return true;
    }


    // returns the current service fee.
    function serviceFee() public view returns (uint256){
        return _service_fee;
    }

    // returns the current single mint service fee.
    function singleMintServiceFee() public view returns (uint256){
        return _single_mint_service_fee;
    }

    // returns the current max bulk mint service fee.
    function maxServiceFee() public view returns (uint256){
        return _max_service_fee;
    }

    // returns the max single mint service fee.
    function maxSingleMintServiceFee() public view returns (uint256){
        return _max_single_mint_service_fee;
    }


    // In this way contract holder can order mass transfer.
    function bulkTransfer(address[] calldata toAddr, uint256[] calldata values) public onlyOwner whenNotPaused {
        require(toAddr.length == values.length && toAddr.length >= 1, "Data for bulk payment not correct!");

        for (uint256 i = 0; i < toAddr.length; i++) {
            transfer(toAddr[i], values[i]);
        }
    }


    // In this way contract holder can order bulk mint.
    function bulkMint(address[] calldata toAddr, uint256[] calldata values, string[] calldata beneficiary) public onlyOwner whenNotPaused {
        require(toAddr.length == values.length && toAddr.length >= 1, "Data for bulk payment not correct!");

        for (uint256 i = 0; i < toAddr.length; i++) {
            mint(toAddr[i], values[i], beneficiary[i]);
        }
    }

    // Custom view showing max minting when capped. Check ERC 20 Capped!!!
    function toBeMinted() public view onlyOwner returns (uint256){
        return _cap - _total_minted;
    }



    // ERC 20 standard implementation from OpenZeppelin done when ERC20 - Pausable is inherited.
    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}