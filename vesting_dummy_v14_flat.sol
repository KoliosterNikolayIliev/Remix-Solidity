// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/vesting_dummy_v14.sol



pragma solidity ^0.8.0;




interface DummyToken is IERC20, IERC20Metadata {}

/**
 * A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time and approval from approver.
 *
 * Useful for vesting schedules like "advisors get their tokens
 * on predefined tim schedule".
 */
contract V14Dummy is Ownable {
    using SafeERC20 for DummyToken;

    // ERC20 basic token contract being held
    DummyToken private immutable _token;

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
    constructor(DummyToken token_) {
        _token = token_;
        _totalBeneficiariesAmount = 0;
        approver = msg.sender;
    }

    event TotalBeneficiariesAmountIncrease(uint256 _value);

    event TotalBeneficiariesAmountDecrease(uint256 _value);

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
    function _currentBalance() private view returns (uint256){
        return token().balanceOf(address(this));
    }

    function currentBalance() external view onlyOwner returns (uint256){
        return _currentBalance();
    }

    /**
     * Returns all beneficiary addresses included in the dummy contract.
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
     * Extends existing dummy vesting scheme.
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
        require(bytes(reason).length >=2,"no reason");
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
            else if (timeNow()<_beneficiaries[beneficiary_][j][1] && _beneficiaries[beneficiary_][j][2] == 0 && _beneficiaries[beneficiary_][j][3] == 0) {
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
