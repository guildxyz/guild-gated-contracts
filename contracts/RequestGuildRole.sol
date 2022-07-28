//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ChainlinkClient } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract RequestGuildRole is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Strings for address;
    using Strings for uint256;

    struct RequestParams {
        address userAddress; // Not really utilized currently, might consider removing it.
        uint256 roleId;
        bytes args;
    }

    mapping(bytes32 => RequestParams) public requests; // TODO: could be made internal.

    uint256 private immutable oracleFee;
    bytes32 private immutable jobId;

    error DelegatecallReverted();
    error NoRole(address userAddress, uint256 roleId);

    event HasRole(address userAddress, uint256 roleId, bool access);

    constructor(
        address linkToken,
        address oracleAddress,
        bytes32 jobId_,
        uint256 oracleFee_
    ) {
        jobId = jobId_;
        oracleFee = oracleFee_;
        setChainlinkToken(linkToken);
        setChainlinkOracle(oracleAddress);
    }

    /// @notice Request the needed data from the oracle.
    /// @param userAddress The address of the user.
    /// @param guildIndex The index of the guild from the membership endpoint, starting from 0.
    /// @param roleId The roleId that has to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfulling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestAccessCheck(
        address userAddress,
        uint256 guildIndex,
        uint256 roleId,
        bytes4 callbackFn,
        bytes memory args
    ) public {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), callbackFn);
        req.add("get", string.concat("https://api.guild.xyz/v1/user/membership/", userAddress.toHexString()));
        req.add("path", string.concat(guildIndex.toString(), ",roleIds"));
        bytes32 requestId = sendOperatorRequest(req, oracleFee);

        RequestParams storage lastRequest = requests[requestId];
        lastRequest.userAddress = userAddress;
        lastRequest.roleId = roleId;
        lastRequest.args = args;
    }

    /// @notice Processes the data returned by the Chainlink node.
    /// @dev Most of this code is just for processing the array.
    /// None of this will be needed when we get the new Guild endpoint, recordChainlinkFulfillment will suffice.
    /// @param requestId The id of the request.
    /// @param returnedArray The array returned by the oracle.
    modifier checkRole(bytes32 requestId, uint256[] memory returnedArray) {
        validateChainlinkCallback(requestId); // Same as the recordChainlinkFulfillment(requestId) modifier.

        RequestParams storage lastRequest = requests[requestId];
        uint256 wantThisRole = lastRequest.roleId;

        // Check if the returned array contains the role that we would like to check
        // and set the result to true if it's found.
        bool access;
        uint256 length = returnedArray.length;
        for (uint256 i; i < length; ) {
            if (returnedArray[i] == wantThisRole) {
                access = true;
                break;
            }

            unchecked {
                ++i;
            }
        }

        if (!access) revert NoRole(lastRequest.userAddress, wantThisRole);

        emit HasRole(lastRequest.userAddress, wantThisRole, access);
        _;
    }
}
