//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ChainlinkClient } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Guild.xyz role checker.
/// @notice Base contract to check an address's roles on Guild.xyz via a Chainlink oracle.
/// @dev Inherit from this contract to have easy access to Guild's access check.
abstract contract RequestGuildRole is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Strings for address;
    using Strings for uint96;

    /// @notice Possible return values from the access endpoint.
    enum Access {
        NO_ACCESS,
        ACCESS,
        CHECK_FAILED
    }

    /// @notice Additional parameters of a request.
    /// @dev `args` are additional arguments to pass to the callback function in an abi-encoded form.
    struct RequestParams {
        address userAddress;
        uint96 roleId;
        bytes args;
    }

    /// @notice The request parameters mapped to the requestIds.
    mapping(bytes32 => RequestParams) internal requests;

    /// @notice The amount of tokens to forward to the oracle with every request.
    uint256 internal immutable oracleFee;

    /// @notice The id of the job to run on the oracle.
    bytes32 internal immutable jobId;

    /// @notice The id of the guild the rewarded role(s) is/are in.
    string internal guildId;

    /// @notice Error thrown when an address doesn't have the needed role.
    /// @param userAddress The address of the queried user.
    /// @param roleId The id of the queried role.
    error NoRole(address userAddress, uint96 roleId);

    /// @notice Error thrown when a role check failed due to an unavailable server or invalid return data.
    /// @param userAddress The address of the queried user.
    /// @param roleId The id of the queried role.
    error CheckingRoleFailed(address userAddress, uint96 roleId);

    /// @notice Event emitted when an address is successfully verified to have a role.
    /// @param userAddress The address of the queried user.
    /// @param roleId The id of the queried role.
    event HasRole(address userAddress, uint96 roleId);

    /// @notice Sets the oracle's details and the guild where the roles are in.
    /// @param linkToken The address of the Chainlink token.
    /// @param oracleAddress The address of the oracle processing the requests.
    /// @param jobId_ The id of the job to run on the oracle.
    /// @param oracleFee_ The amount of tokens to forward to the oracle with every request.
    /// @param guildId_ The id of the guild the queried role(s) is/are in.
    constructor(
        address linkToken,
        address oracleAddress,
        bytes32 jobId_,
        uint256 oracleFee_,
        string memory guildId_
    ) {
        jobId = jobId_;
        oracleFee = oracleFee_;
        guildId = guildId_;
        setChainlinkToken(linkToken);
        setChainlinkOracle(oracleAddress);
    }

    /// @notice Requests the needed data from the oracle.
    /// @param userAddress The address of the user.
    /// @param roleId The roleId that has to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfulling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestAccessCheck(
        address userAddress,
        uint96 roleId,
        bytes4 callbackFn,
        bytes memory args
    ) internal {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), callbackFn);
        req.add(
            "get",
            string.concat(
                "https://api.guild.xyz/v1/guild/access/",
                guildId,
                "/",
                userAddress.toHexString(),
                "?format=oracle"
            )
        );
        req.add("path", roleId.toString());
        req.addInt("multiply", 1);
        bytes32 requestId = sendChainlinkRequest(req, oracleFee);

        RequestParams storage lastRequest = requests[requestId];
        lastRequest.userAddress = userAddress;
        lastRequest.roleId = roleId;
        lastRequest.args = args;
    }

    /// @notice Processes the data returned by the Chainlink node.
    /// @dev Most of this code is just for processing the array.
    /// None of this will be needed when we get the new Guild endpoint, recordChainlinkFulfillment will suffice.
    /// @param requestId The id of the request.
    /// @param access The value returned by the oracle.
    modifier checkRole(bytes32 requestId, uint256 access) {
        validateChainlinkCallback(requestId); // Same as the recordChainlinkFulfillment(requestId) modifier.

        RequestParams storage lastRequest = requests[requestId];

        if (access == uint256(Access.NO_ACCESS)) revert NoRole(lastRequest.userAddress, lastRequest.roleId);
        if (access >= uint256(Access.CHECK_FAILED))
            revert CheckingRoleFailed(lastRequest.userAddress, lastRequest.roleId);

        emit HasRole(lastRequest.userAddress, lastRequest.roleId);
        _;
    }
}
