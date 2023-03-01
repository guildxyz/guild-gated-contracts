// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 * @title The Chainlink Mock Oracle contract.
 * @notice Chainlink smart contract developers can use this to test their contracts.
 * @dev Updated for Solidity ^0.8.0.
 */
contract MockOperator {
    uint256 public constant EXPIRY_TIME = 5 minutes;
    uint256 private constant MINIMUM_CONSUMER_GAS_LIMIT = 400000;

    struct Request {
        address callbackAddr;
        bytes4 callbackFunctionId;
    }

    LinkTokenInterface internal linkToken;
    mapping(bytes32 => Request) private commitments;

    event OracleRequest(
        bytes32 indexed specId,
        address requester,
        bytes32 requestId,
        uint256 payment,
        address callbackAddr,
        bytes4 callbackFunctionId,
        uint256 cancelExpiration,
        uint256 dataVersion,
        bytes data
    );

    event CancelOracleRequest(bytes32 indexed requestId);

    /**
     * @notice Deploy with the address of the LINK token.
     * @dev Sets the linkToken address for the imported LinkTokenInterface.
     * @param _link The address of the LINK token.
     */
    constructor(address _link) {
        linkToken = LinkTokenInterface(_link);
    }

    /**
     * @notice Creates the Chainlink request.
     * @dev Stores the hash of the params as the on-chain commitment for the request.
     * Emits OracleRequest event for the Chainlink node to detect.
     * @param _sender The sender of the request.
     * @param _payment The amount of payment given (specified in wei).
     * @param _specId The Job Specification ID.
     * @param _callbackAddress The callback address for the response
     * @param _callbackFunctionId The callback function ID for the response.
     * @param _nonce The nonce sent by the requester.
     * @param _dataVersion The specified data version.
     * @param _data The CBOR payload of the request.
     */
    function oracleRequest(
        address _sender,
        uint256 _payment,
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce,
        uint256 _dataVersion,
        bytes calldata _data
    ) external validateFromLINK {
        bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
        require(commitments[requestId].callbackAddr == address(0), "Must use a unique ID");
        uint256 expiration = block.timestamp + EXPIRY_TIME;

        commitments[requestId] = Request(_callbackAddress, _callbackFunctionId);

        emit OracleRequest(
            _specId,
            _sender,
            requestId,
            _payment,
            _callbackAddress,
            _callbackFunctionId,
            expiration,
            _dataVersion,
            _data
        );
    }

    /**
     * @notice Called by the Chainlink node to fulfill requests.
     * @dev Given params must hash back to the commitment stored from `oracleRequest`.
     * Will call the callback address's callback function without bubbling up error
     * checking in a `require` so that the node can get paid.
     * @param _requestId The fulfillment request ID that must match the requester's.
     * @param _data The data to return to the consuming contract.
     * @return Status if the external call was successful.
     */
    function fulfillOracleRequest(
        bytes32 _requestId,
        bytes32 _data
    ) external isValidRequest(_requestId) returns (bool) {
        Request memory req = commitments[_requestId];
        delete commitments[_requestId];
        require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
        // All updates to the oracle's fulfillment should come before calling the
        // callback(addr+functionId) as it is untrusted.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = req.callbackAddr.call(abi.encodeWithSelector(req.callbackFunctionId, _requestId, _data));
        return success;
    }

    /**
     * @notice Called by the Chainlink node to fulfill multiword requests.
     * @dev Given params must hash back to the commitment stored from `oracleRequest`.
     * Will call the callback address's callback function without bubbling up error
     * checking in a `require` so that the node can get paid.
     * @param _requestId The fulfillment request ID that must match the requester's.
     * @param _data The data to return to the consuming contract.
     * @return Status if the external call was successful.
     */
    function fulfillOracleRequest2(
        bytes32 _requestId,
        bytes calldata _data
    ) external isValidRequest(_requestId) validateMultiWordResponseId(_requestId, _data) returns (bool) {
        Request memory req = commitments[_requestId];
        delete commitments[_requestId];
        require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
        // All updates to the oracle's fulfillment should come before calling the
        // callback(addr+functionId) as it is untrusted.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = req.callbackAddr.call(abi.encodePacked(req.callbackFunctionId, _data));
        return success;
    }

    /**
     * @notice Same as fulfillOracleRequest but bubbles up error data.
     * @dev Useful for testing.
     * @param _requestId The fulfillment request ID that must match the requester's.
     * @param _data The data to return to the consuming contract.
     * @return Status if the external call was successful.
     */
    function tryFulfillOracleRequest(
        bytes32 _requestId,
        bytes32 _data
    ) external isValidRequest(_requestId) returns (bool) {
        Request memory req = commitments[_requestId];
        delete commitments[_requestId];
        require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
        // All updates to the oracle's fulfillment should come before calling the
        // callback(addr+functionId) as it is untrusted.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = req.callbackAddr.call(
            abi.encodeWithSelector(req.callbackFunctionId, _requestId, _data)
        );
        if (!success) handleRevert(returndata);
        return success;
    }

    /**
     * @notice Same as fulfillOracleRequest2 but bubbles up error data.
     * @dev Useful for testing.
     * @param _requestId The fulfillment request ID that must match the requester's.
     * @param _data The data to return to the consuming contract.
     * @return Status if the external call was successful.
     */
    function tryFulfillOracleRequest2(
        bytes32 _requestId,
        bytes calldata _data
    ) external isValidRequest(_requestId) validateMultiWordResponseId(_requestId, _data) returns (bool) {
        Request memory req = commitments[_requestId];
        delete commitments[_requestId];
        require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
        // All updates to the oracle's fulfillment should come before calling the
        // callback(addr+functionId) as it is untrusted.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = req.callbackAddr.call(
            abi.encodePacked(req.callbackFunctionId, _data)
        );
        if (!success) handleRevert(returndata);
        return success;
    }

    /**
     * @notice Allows requesters to cancel requests sent to this oracle contract. Will transfer the LINK
     * sent for the request back to the requester's address.
     * @dev Given params must hash to a commitment stored on the contract in order for the request to be valid
     * Emits CancelOracleRequest event.
     * @param _requestId The request ID.
     * @param _payment The amount of payment given (specified in wei).
     * @param _expiration The time of the expiration for the request.
     */
    function cancelOracleRequest(bytes32 _requestId, uint256 _payment, bytes4, uint256 _expiration) external {
        require(commitments[_requestId].callbackAddr != address(0), "Must use a unique ID");
        // solhint-disable-next-line not-rely-on-time
        require(_expiration <= block.timestamp, "Request is not expired");

        delete commitments[_requestId];
        emit CancelOracleRequest(_requestId);

        assert(linkToken.transfer(msg.sender, _payment));
    }

    /**
     * @notice Called when LINK is sent to the contract via `transferAndCall`
     * @dev The data payload's first 2 words will be overwritten by the `sender` and `amount`
     * values to ensure correctness. Calls oracleRequest.
     * @dev Taken from LinkTokenReceiver.sol.
     * @param sender Address of the sender.
     * @param amount Amount of LINK sent (specified in wei).
     * @param data Payload of the transaction.
     */
    function onTokenTransfer(address sender, uint256 amount, bytes memory data) public validateFromLINK {
        assembly {
            // solhint-disable-next-line avoid-low-level-calls
            mstore(add(data, 36), sender) // ensure correct sender is passed
            // solhint-disable-next-line avoid-low-level-calls
            mstore(add(data, 68), amount) // ensure correct amount is passed
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).delegatecall(data); // calls oracleRequest
        require(success, "Unable to create request");
    }

    /**
     * @notice Returns the address of the LINK token.
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     * an internal method of the ChainlinkClient contract.
     */
    function getChainlinkToken() public view returns (address) {
        return address(linkToken);
    }

    /**
     * @dev Get the revert reason or custom error from a bytes array and revert with it.
     */
    function handleRevert(bytes memory returndata) internal pure {
        if (returndata.length > 0) {
            // If there is a revert reason, get it.
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert("Unknown reason");
        }
    }

    // MODIFIERS

    /**
     * @dev Reverts if request ID does not exist.
     * @param _requestId The given request ID to check in stored `commitments`.
     */
    modifier isValidRequest(bytes32 _requestId) {
        require(commitments[_requestId].callbackAddr != address(0), "Must have a valid requestId");
        _;
    }

    /**
     * @dev Reverts if the callback address is the LINK token.
     * @param _to The callback address.
     */
    modifier checkCallbackAddress(address _to) {
        require(_to != address(linkToken), "Cannot callback to LINK");
        _;
    }

    /**
     * @dev Reverts if not sent from the LINK token.
     * @dev Taken from LinkTokenReceiver.sol.
     */
    modifier validateFromLINK() {
        require(msg.sender == address(linkToken), "Must use LINK token");
        _;
    }

    /**
     * @dev Reverts if the first 32 bytes of the bytes array is not equal to requestId
     * @param requestId bytes32
     * @param data bytes
     */
    modifier validateMultiWordResponseId(bytes32 requestId, bytes calldata data) {
        require(data.length >= 32, "Response must be > 32 bytes");
        bytes32 firstDataWord;
        assembly {
            // extract the first word from data
            // functionSelector = 4
            // wordLength = 32
            // dataArgumentOffset = 7 * wordLength
            // funcSelector + dataArgumentOffset == 0xe4
            firstDataWord := calldataload(0xe4)
        }
        require(requestId == firstDataWord, "First word must be requestId");
        _;
    }
}
