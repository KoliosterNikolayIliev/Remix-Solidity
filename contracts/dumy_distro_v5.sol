// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface DummyToken is IERC20, IERC20Metadata {}

/**
 * A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for vesting schedules like "advisors get their tokens
 * on predefined tim schedule".
 */
contract V5Dummy is Ownable {
    using SafeERC20 for DummyToken;

    // ERC20 basic token contract being held
    DummyToken private immutable _token;

    mapping(address => uint256[4][]) private _beneficiaries;
    mapping(address => string[]) private _canceledPaymentsDueToReason;
    mapping(address => address) private _changed_wallet;
    address[] private  _changed_wallets_list;
    address[] private _canceledPaymentsAddressList;
    uint256  private _totalBeneficiariesAmount;
    // holds a list with all beneficiaries
    address[] private _beneficiary_list;
    address public approver;

    /**
     *  Deploys a time-lock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_ (parameter at index 1 in  address => uint256[3][])`.
     *  The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        DummyToken token_
    ) {
        _token = token_;
        _totalBeneficiariesAmount = 0;
        approver = msg.sender;
    }

    /**
     * Returns the token being held.
     */
    function token() public view returns (DummyToken) {
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
    function currentBalance() public view returns (uint256){
        return token().balanceOf(address(this));
    }

    /**
     * Returns all beneficiary addresses included in the dummy contract.
     */
    function returnBeneficiaryList() external view returns (address[] memory){
        return _beneficiary_list;
    }

    /**
    * Returns the difference between token balance and locked tokens if any.
    */
    function currentNonUtilizedAmount() public view returns (uint256){
        require(currentBalance() >= totalUnreleasedPayments());
        uint256 result = currentBalance() - totalUnreleasedPayments();
        return result;
    }

    /**
     * Returns the sum of all locked tokens.
     */
    function totalUnreleasedPayments() public view returns (uint256){
        return _totalBeneficiariesAmount;
    }

    /**
    * Renounce ownership not possible with this smart contract.
    */
    function renounceOwnership() public onlyOwner view override  (Ownable) {
        revert("This contract doesn't support renouncing of ownership");

    }

    /**
     * Returns array with all payments(released and not released) for given beneficiary that will receive the tokens.
     */
    function beneficiary(address beneficiary_) external view returns (uint256[4][] memory){
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        return _beneficiaries[beneficiary_];
    }

    /**
     * Returns array with addresses of beneficiaries with canceled payments.
     */
    function getCanceledPaymentsAddresses() external view returns (address[] memory){
        return _canceledPaymentsAddressList;
    }

    /**
     * Returns reason for cancellation of payments of beneficiary.
     */
    function getReasonForCancellation(address beneficiary_) external view returns (string[] memory){
        uint256 counter = 0;
        for (uint256 i = 0; i < _canceledPaymentsAddressList.length; i++) {
            if (beneficiary_ == _canceledPaymentsAddressList[i]) {
                counter++;
            }
        }
        require(counter > 0, "Beneficiary does not have canceled payments!");
        return _canceledPaymentsDueToReason[beneficiary_];
    }

    /**
     * Add beneficiary with initial tokens to be received.
     */
    function addBeneficiary(address beneficiary_, uint256[] calldata amounts, uint256[] calldata releaseDates) external onlyOwner {
        require(amounts.length == releaseDates.length && amounts.length >= 1, "Data for not correct!. Count of release dates and amounts must be equal!");
        require(_beneficiaries[beneficiary_].length == 0, "Beneficiary already existing!");
        uint256 paid = 0;
        uint256 approved = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(timeNow() < releaseDates[i], "Release date can't be equal or less than current date!");
            _totalBeneficiariesAmount += amounts[i];
            require(_totalBeneficiariesAmount <= currentBalance(), "Insufficient balance! Can't add new beneficiaries!");
            _beneficiaries[beneficiary_].push([amounts[i], releaseDates[i], paid, approved]);
        }

        _beneficiary_list.push(beneficiary_);
    }

    /**
     * Add additional payments to beneficiary.
     */

    function addPaymentToBeneficiary(address beneficiary_, uint256 amount, uint256 releaseDate) external onlyOwner {
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        require(amount + _totalBeneficiariesAmount <= currentBalance(), "Insufficient balance! Can't add new payments!");
        require(_beneficiaries[beneficiary_][_beneficiaries[beneficiary_].length - 1][1] < releaseDate, "Future release date can't be equal or less than the last entered!");
        require(timeNow() < releaseDate, "Release date can't be equal or less than current date!");
        uint256 paid = 0;
        uint256 approved = 0;
        _totalBeneficiariesAmount += amount;
        _beneficiaries[beneficiary_].push([amount, releaseDate, paid, approved]);
    }


    /**
     * Removes all non released payments to a beneficiary. Only owner can call it in special circumstances.
     * Normally only non approved payments before due date are deleted.
     * Non approved payments after due date can also be deleted (by using force delete). In this way locked tokens from beneficiary with stopped payments,
       can be freed up.
     */
    function cancelPaymentsToBeneficiary(address beneficiary_, string calldata reason, bool force_delete) external onlyOwner {
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        uint256 j;
        uint256 counter = 0;
        for (uint256 i = _beneficiaries[beneficiary_].length; i > 0; i--) {
            j = i - 1;
            if (force_delete && _beneficiaries[beneficiary_][j][3] == 0) {
                counter++;
                _totalBeneficiariesAmount -= _beneficiaries[beneficiary_][j][0];
                string.concat("Force deleted due to: ", reason);
            }
            else if (timeNow() < _beneficiaries[beneficiary_][j][1] && _beneficiaries[beneficiary_][j][2] == 0 && _beneficiaries[beneficiary_][j][3] == 0) {
                counter++;
                _totalBeneficiariesAmount -= _beneficiaries[beneficiary_][j][0];
            }
            else {
                break;
            }
        }
        if (counter == 0) {
            revert("No payments to cancel!");
        }
        _canceledPaymentsDueToReason[beneficiary_].push(reason);
        // TODO use addElement to array?
        _canceledPaymentsAddressList.push(beneficiary_);
        while (counter > 0) {
            _beneficiaries[beneficiary_].pop();
            counter--;
        }
        if (_beneficiaries[beneficiary_].length == 0) {
            delete _beneficiaries[beneficiary_];
            uint256 index;
            for (uint256 i = 0; i < _beneficiary_list.length; i++) {
                if (beneficiary_ == _beneficiary_list[i]) {
                    index = i;
                    break;
                }
            }
            orderedRemoveFromBeneficiaryList(index);
        }
    }


    /**
     * Removes beneficiary from the list if the beneficiary is deleted.Does not keep order of the array.
     */
    function fastRemoveFromBeneficiaryList(uint index) private {
        _beneficiary_list[index] = _beneficiary_list[_beneficiary_list.length - 1];
        _beneficiary_list.pop();
    }

    /**
     * Removes beneficiary from the list if the beneficiary is deleted.Does keep order of the array.
     */

    function orderedRemoveFromBeneficiaryList(uint index) private {

        for (uint i = index; i < _beneficiary_list.length - 1; i++) {
            _beneficiary_list[i] = _beneficiary_list[i + 1];
        }
        _beneficiary_list.pop();
    }



    /**
     * Beneficiary can change wallet address for some reason. Can be done only by the beneficiary
     */
    function changeBeneficiaryWallet(address newBeneficiary) external {
        require(_beneficiaries[msg.sender].length > 0, "Only existing beneficiary can change wallet address!");
        uint256[4][] memory old;
        old = _beneficiaries[msg.sender];
        delete _beneficiaries[msg.sender];
        _beneficiaries[newBeneficiary] = old;
        uint256 index;
        for (uint256 i = 0; i < _beneficiary_list.length; i++) {
            address beneficiary_ = msg.sender;
            if (beneficiary_ == _beneficiary_list[i]) {
                index = i;
                break;
            }
        }
        _beneficiary_list[index] = newBeneficiary;
        _changed_wallets_list.push(msg.sender);
        _changed_wallet[msg.sender] = newBeneficiary;

    }

    function addElementToArray(address element, address[] storage elements) private {
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

    function changedWallets() external view onlyOwner returns (address[] memory){
        return _changed_wallets_list;
    }

    function checkWalletChange(address wallet) external view onlyOwner returns (address){
        require(_changed_wallet[wallet] != 0x0000000000000000000000000000000000000000, "Wallet has never changed!");
        return _changed_wallet[wallet];
    }

    /**
     * Checks if there are released payments for a beneficiary and transfers the tokens to the beneficiary.
     * Can be called by Owner of the contract or the beneficiary.
     */
    function release(address beneficiary_) external {
        require(msg.sender == owner() || msg.sender == beneficiary_, "Withdraw can be done only by contract owner or beneficiary!");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");

        uint256 counter = 0;
        uint256 approved = 1;
        uint256 paid = 1;
        for (uint256 i = 0; i < _beneficiaries[beneficiary_].length; i++) {
            if (_beneficiaries[beneficiary_][i][2] == paid) {
                continue;
            }
            if (_beneficiaries[beneficiary_][i][3] != approved) {
                break;
            }
            if (_beneficiaries[beneficiary_][i][1] >= timeNow()) {
                break;
            }
            _beneficiaries[beneficiary_][i][2] = paid;
            _totalBeneficiariesAmount -= _beneficiaries[beneficiary_][i][0];
            token().safeTransfer(beneficiary_, _beneficiaries[beneficiary_][i][0]);
            counter++;
        }
        if (counter == 0) {
            revert("No released payments for transfer! Possible reasons: payment/s not approved, release before due date, no existing payments.");
        }
    }

    /**
     * Owner can transfer excess balance(after canceling of payments) to address of his choice.
     */
    function transferExcessBalance(address wallet) external onlyOwner {
        require(currentBalance() > totalUnreleasedPayments(), "No excess tokens to transfer!");
        uint256 amount = currentNonUtilizedAmount();
        token().safeTransfer(wallet, amount);
    }


    /**
     * Default approver is owner. Owner can change it.
     */
    function changeApprover(address wallet) external onlyOwner returns (bool){
        approver = wallet;
        return true;
    }

    /**
     * Approve payment.
     */

    function approvePayment(address beneficiary_, uint256[] calldata indexes) public {
        require(msg.sender == approver, "Only approver can approve paymnets!");
        require(_beneficiaries[beneficiary_].length > 0, "Beneficiary not existing!");
        require(_beneficiaries[beneficiary_].length <= indexes.length, "Wrong payment data!");
        for (uint256 i = 0; i < indexes.length; i++) {
            _beneficiaries[beneficiary_][indexes[i]][3] = 1;
        }
    }


    function massApproval(address[] calldata beneficiaries_, uint256[][] calldata indexes_per_beneficiary) public {
        require(msg.sender == approver);
        require(beneficiaries_.length > 0, "List of beneficiaries is required");
        require(indexes_per_beneficiary.length == beneficiaries_.length, "Indexes for payments per beneficiary must be provided!");

        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            require(indexes_per_beneficiary[i].length > 0, "List of payments per beneficiary can't be empty!");
            approvePayment(beneficiaries_[i], indexes_per_beneficiary[i]);
        }
    }
}