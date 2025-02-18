// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Token is IERC20, IERC20Metadata {}

/**
 * A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time and approval from approver.
 *
 * Useful for vesting schedules like "advisors get their tokens
 * on predefined tim schedule".
 */
contract VestingTeamAndAdvisors is Ownable {
    using SafeERC20 for Token;

    // ERC20 basic token contract being held
    Token private immutable _token;

    mapping(address => uint256[4][]) private _beneficiaries;
    mapping(address => string[]) private _canceledPaymentsDueToReason;
    mapping(address => address) private _changedWallet;
    address[] private  _changedWalletsList;
    address[] private _canceledPaymentsAddressList;
    uint256  private _totalBeneficiariesAmount;
    // holds a list with all beneficiaries
    address[] private _beneficiaryList;
    address public approver;

    /**
     *  Deploys a time-lock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_ (parameter at index 1 in  address => uint256[3][])`.
     *  The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(Token token_) {
        _token = token_;
        _totalBeneficiariesAmount = 0;
        approver = msg.sender;
    }

    event TotalBeneficiariesAmountIncrease(uint256 _value);

    event TotalBeneficiariesAmountDecrease(uint256 _value);

    /**
     * Returns the token being held.
     */
    function token() public view returns (Token) {
        return _token;
    }

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
    function _currentBalance() private view returns (uint256){
        return token().balanceOf(address(this));
    }

    function currentBalance() external view onlyOwner returns (uint256){
        return _currentBalance();
    }

    /**
     * Returns all beneficiary addresses included in the vesting contract.
     */
    function returnBeneficiaryList() external view onlyOwner returns (address[] memory){
        return _beneficiaryList;
    }

    /**
    * Returns the difference between token balance and locked tokens if any.
    */
    function _currentNonUtilizedAmount() private view returns (uint256){
        require(_currentBalance() >= _totalBeneficiariesAmount, "0");
        uint256 result = _currentBalance() - _totalBeneficiariesAmount;
        return result;
    }

    function currentNonUtilizedAmount() public view onlyOwner returns (uint256){
        return _currentNonUtilizedAmount();
    }

    /**
     * Returns the sum of all locked tokens.
     */
    function totalUnreleasedPayments() external view onlyOwner returns (uint256){
        return _totalBeneficiariesAmount;
    }

    /**
    * Renounce ownership not possible with this smart contract.
    */
    function renounceOwnership() public onlyOwner view override  (Ownable) {
        revert("Doesn't support renouncing of ownership!");
    }


    /**
     * Returns array with all payments (released and not released) for given beneficiary that will receive the tokens.
     */
    function beneficiary(address beneficiary_) external view returns (uint256[4][] memory){
        require(msg.sender == owner() || msg.sender == beneficiary_, "Not beneficiary!");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        return _beneficiaries[beneficiary_];
    }

    /**
     * Returns array with addresses of beneficiaries with canceled payments.
     */
    function getCanceledPaymentsAddresses() external view onlyOwner returns (address[] memory){
        return _canceledPaymentsAddressList;
    }

    /**
     * Returns reason for cancellation of payments of beneficiary.
     */
    function getReasonForCancellation(address beneficiary_) external view returns (string[] memory){
        require(msg.sender == owner() || msg.sender == beneficiary_, "Only beneficiary or owner!");
        uint256 counter = 0;
        for (uint256 i = 0; i < _canceledPaymentsAddressList.length; i++) {
            if (beneficiary_ == _canceledPaymentsAddressList[i]) {
                counter++;
            }
        }
        require(counter > 0, "No canceled payments!");
        return _canceledPaymentsDueToReason[beneficiary_];
    }

    /**
     * Add beneficiary with initial tokens to be received.
     */
    function addBeneficiary(address beneficiary_, uint256[] calldata amounts, uint256[] calldata releaseDates) external onlyOwner {
        require(amounts.length == releaseDates.length && amounts.length >= 1, "Data not correct!");
        require(_beneficiaries[beneficiary_].length == 0, "Beneficiary already existing!");
        _addMultiplePayments(beneficiary_, amounts, releaseDates);
        _beneficiaryList.push(beneficiary_);
    }

    /**
     * Add multiple payments to beneficiary.
     */
    function _addMultiplePayments(address beneficiary_, uint256[] calldata amounts, uint256[] calldata releaseDates) private {
        uint256 paid = 0;
        uint256 approved = 0;
        uint256 totalCurrentBeneficiaryAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(timeNow() < releaseDates[i], "Release date can't be equal or less than current date!");
            totalCurrentBeneficiaryAmount += amounts[i];
            require(_totalBeneficiariesAmount + totalCurrentBeneficiaryAmount <= _currentBalance(), "Insufficient balance!");
            _beneficiaries[beneficiary_].push([amounts[i], releaseDates[i], paid, approved]);
        }
        _totalBeneficiariesAmount += totalCurrentBeneficiaryAmount;
        emit TotalBeneficiariesAmountIncrease(totalCurrentBeneficiaryAmount);
    }

    /**
     * Add additional payments to beneficiary.
     */
    function addPaymentToBeneficiary(address beneficiary_, uint256 amount, uint256 releaseDate) external onlyOwner {
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        require(amount + _totalBeneficiariesAmount <= _currentBalance(), "Insufficient balance!");
        require(_beneficiaries[beneficiary_][_beneficiaries[beneficiary_].length - 1][1] < releaseDate, "Date can't be less than the last entered!");
        require(timeNow() < releaseDate, "Date can't be equal or less than current date!");
        _totalBeneficiariesAmount += amount;
        emit TotalBeneficiariesAmountIncrease(amount);
        _beneficiaries[beneficiary_].push([amount, releaseDate, 0, 0]);
    }

    /**
     * Extends existing vesting scheme.
     */
    function extendExistingVesting(address beneficiary_, uint256[] calldata amounts, uint256[] calldata releaseDates) external onlyOwner {
        require(amounts.length == releaseDates.length && amounts.length >= 1, "Input not correct!.");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        _addMultiplePayments(beneficiary_, amounts, releaseDates);
    }


    /**
     * Removes all non released payments to a beneficiary. Only owner can call it in special circumstances.
     * Normally only non approved payments before due date are deleted.
     * Non approved payments after due date can also be deleted (by using force delete). In this way locked tokens from beneficiary with stopped payments,
       can be freed up.
     */
    function cancelPaymentsToBeneficiary(address beneficiary_, string calldata reason, bool forceDelete) external onlyOwner {
        require(bytes(reason).length >= 2, "no reason");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        uint256 j;
        uint256 counter = 0;
        uint256 removeFromTotalBeneficiariesAmount = 0;
        for (uint256 i = _beneficiaries[beneficiary_].length; i > 0; i--) {
            j = i - 1;
            if (forceDelete && _beneficiaries[beneficiary_][j][3] == 0) {
                counter++;
                removeFromTotalBeneficiariesAmount += _beneficiaries[beneficiary_][j][0];
                string.concat("Force deleted due to: ", reason);
            }
            else if (timeNow() < _beneficiaries[beneficiary_][j][1] && _beneficiaries[beneficiary_][j][2] == 0 && _beneficiaries[beneficiary_][j][3] == 0) {
                counter++;
                removeFromTotalBeneficiariesAmount += _beneficiaries[beneficiary_][j][0];
            }
            else {
                break;
            }
        }

        require(counter > 0, "No payments to cancel!");
        _totalBeneficiariesAmount -= removeFromTotalBeneficiariesAmount;
        _canceledPaymentsDueToReason[beneficiary_].push(reason);
        _addElementToArray(beneficiary_, _canceledPaymentsAddressList);
        emit TotalBeneficiariesAmountDecrease(removeFromTotalBeneficiariesAmount);

        while (counter > 0) {
            _beneficiaries[beneficiary_].pop();
            counter--;
        }
        if (_beneficiaries[beneficiary_].length == 0) {
            delete _beneficiaries[beneficiary_];
            address[] memory modifiedList = _beneficiaryList;
            for (uint256 i = 0; i < _beneficiaryList.length; i++) {
                if (beneficiary_ == _beneficiaryList[i]) {
                    modifiedList = _orderedRemoveFromBeneficiaryList(i, _beneficiaryList);
                    break;
                }
            }
            _beneficiaryList = modifiedList;
        }
    }

    /**
     * Removes item from array and keeps order of the array.
     */
    function _orderedRemoveFromBeneficiaryList(uint index, address[] storage modifiedList) private returns (address[] memory){

        for (uint i = index; i < modifiedList.length - 1; i++) {
            modifiedList[i] = modifiedList[i + 1];
        }
        modifiedList.pop();
        return modifiedList;
    }



    /**
     * Beneficiary can change wallet address for some reason. Can be done only by the beneficiary.
     */
    function changeBeneficiaryWallet(address newBeneficiary) external {
        require(_beneficiaries[msg.sender].length > 0, "Only beneficiary can change wallet address!");
        require(_beneficiaries[newBeneficiary].length <= 0, "Already existing in vesting!");
        uint256[4][] memory old;
        old = _beneficiaries[msg.sender];
        delete _beneficiaries[msg.sender];
        _beneficiaries[newBeneficiary] = old;

        for (uint256 i = 0; i < _beneficiaryList.length; i++) {
            address beneficiary_ = msg.sender;
            if (beneficiary_ == _beneficiaryList[i]) {
                _beneficiaryList[i] = newBeneficiary;
                break;
            }
        }
        _changedWalletsList.push(msg.sender);
        _changedWallet[msg.sender] = newBeneficiary;

    }

    function _addElementToArray(address element, address[] storage elements) private {
        bool found = false;
        for (uint256 i = 0; i < elements.length; i++) {
            if (element == elements[i]) {
                found = true;
                break;
            }
        }
        if (!found) {
            elements.push(element);
        }
    }

    // returns list with wallets that have been changed
    function changedWallets() external view onlyOwner returns (address[] memory){
        return _changedWalletsList;
    }

    // checks if a beneficiary has wallet change.
    function checkWalletChange(address wallet) external view onlyOwner returns (address){
        require(_changedWallet[wallet] != address(0), "Wallet has never changed!");
        return _changedWallet[wallet];
    }

    /**
     * Checks if there are released payments for a beneficiary and transfers the tokens to the beneficiary.
     * Can be called by Owner of the contract or the beneficiary.
     */
    function release(address beneficiary_) external {
        require(msg.sender == owner() || msg.sender == beneficiary_, "Only beneficiary!");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");

        uint256 counter = 0;
        uint256 approved = 1;
        uint256 paid = 1;
        uint256 removeFromTotalBeneficiariesAmount = 0;

        for (uint256 i = 0; i < _beneficiaries[beneficiary_].length; i++) {
            if (_beneficiaries[beneficiary_][i][2] == paid) {
                continue;
            }
            if (_beneficiaries[beneficiary_][i][3] != approved) {
                continue;
            }
            if (_beneficiaries[beneficiary_][i][1] >= timeNow()) {
                break;
            }
            _beneficiaries[beneficiary_][i][2] = paid;
            removeFromTotalBeneficiariesAmount += _beneficiaries[beneficiary_][i][0];
            token().safeTransfer(beneficiary_, _beneficiaries[beneficiary_][i][0]);
            counter++;
        }
        if (removeFromTotalBeneficiariesAmount > 0) {
            _totalBeneficiariesAmount -= removeFromTotalBeneficiariesAmount;
        }

        if (counter == 0) {
            revert("Nothing for transfer!");
        }
    }

    /**
     * Owner can transfer excess balance(after canceling of payments or other reason for unutilized payments) to address of his choice.
     */
    function transferExcessBalance(address wallet) external onlyOwner {

        uint256 amount = _currentNonUtilizedAmount();
        require(amount > 0, "No tokens to transfer!");
        token().safeTransfer(wallet, amount);
    }


    /**
     * Default approver is owner. Owner can change it.
     */
    function changeApprover(address wallet) external onlyOwner returns (bool){
        require(wallet != approver, "Can't change. This is the current approver!");
        require(wallet != address(0), "Can't be zero address!");
        approver = wallet;
        return true;
    }

    /**
     * Approve payment.
     */
    function approvePayment(address beneficiary_, uint256[] calldata indexes) public {
        require(msg.sender == approver, "Only approver can approve payments!");
        require(indexes.length > 0, "No selected payments for approval!");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        require(_beneficiaries[beneficiary_].length >= indexes.length, "Wrong payment data!");
        for (uint256 i = 0; i < indexes.length; i++) {
            require(indexes[i] < _beneficiaries[beneficiary_].length, "Index error, no such payment!");
            require(_beneficiaries[beneficiary_][indexes[i]][3] == 0, "Payment already approved!");
            if (indexes[i] > 0) {
                require(_beneficiaries[beneficiary_][indexes[i] - 1][3] == 1, "Can't approve next payment before the previous one!");
            }
            _beneficiaries[beneficiary_][indexes[i]][3] = 1;
        }
    }

    /**
     * Mass approval of payments payment.
     */
    function massApproval(address[] calldata beneficiaries, uint256[][] calldata indexesPerBeneficiary) public {
        require(msg.sender == approver, "Only approver can approve payments!");
        require(beneficiaries.length > 0, "List of beneficiaries is required");
        require(indexesPerBeneficiary.length == beneficiaries.length, "Indexes for payments per beneficiary must be provided!");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(indexesPerBeneficiary[i].length > 0, "List of payments per beneficiary can't be empty!");
            approvePayment(beneficiaries[i], indexesPerBeneficiary[i]);
        }
    }
}
