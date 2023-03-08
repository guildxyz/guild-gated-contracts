//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ChainlinkClient } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Guild Oracle.
/// @notice Base contract to check an address's accesses, roles, admin/owner status on Guild.xyz via a Chainlink oracle.
/// @dev Inherit from this contract to have easy access to Guild's access check.
abstract contract GuildOracle is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Strings for address;
    using Strings for uint256;

    /// @notice Possible return values from the Guild endpoint.
    enum Access {
        NO_ACCESS,
        ACCESS,
        CHECK_FAILED
    }

    /// @notice Additional parameters of a request.
    /// @dev `args` are additional arguments to pass to the callback function in an abi-encoded form.
    struct RequestParams {
        address userAddress;
        bytes args;
    }

    /// @notice The request parameters mapped to the requestIds.
    mapping(bytes32 => RequestParams) internal requests;

    /// @notice The amount of tokens to forward to the oracle with every request.
    uint256 internal immutable oracleFee;

    /// @notice The id of the job to run on the oracle.
    bytes32 internal immutable jobId;

    /// @notice Error thrown when an address doesn't have the needed role.
    /// @param userAddress The address of the queried user.
    error NoAccess(address userAddress);

    /// @notice Error thrown when a role check failed due to an unavailable server or invalid return data.
    /// @param userAddress The address of the queried user.
    error AccessCheckFailed(address userAddress);

    /// @notice Event emitted when an address is successfully verified to have a role.
    /// @param userAddress The address of the queried user.
    event HasAccess(address userAddress);

    /// @notice Sets the oracle's details.
    /// @param linkToken The address of the Chainlink token.
    /// @param oracleAddress The address of the oracle processing the requests.
    /// @param jobId_ The id of the job to run on the oracle.
    /// @param oracleFee_ The amount of tokens to forward to the oracle with every request.
    constructor(address linkToken, address oracleAddress, bytes32 jobId_, uint256 oracleFee_) {
        jobId = jobId_;
        oracleFee = oracleFee_;
        setChainlinkToken(linkToken);
        setChainlinkOracle(oracleAddress);
    }

    /// @notice Sends a request to the oracle querying if the user has access to a certain role on Guild.
    /// @dev The user may not actually hold the role.
    /// @param addressToCheck The address of the user.
    /// @param guildId The id of the guild the rewarded role is in.
    /// @param roleId The roleId that has to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfilling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestGuildRoleAccessCheck(
        address addressToCheck,
        uint256 roleId,
        uint256 guildId,
        bytes4 callbackFn,
        bytes memory args
    ) internal {
        requestOracle(
            addressToCheck,
            string.concat(
                "https://api.guild.xyz/v1/guild/access/",
                guildId.toString(),
                "/",
                addressToCheck.toHexString(),
                "?format=oracle"
            ),
            roleId.toString(),
            callbackFn,
            args
        );
    }

    /// @notice Sends a request to the oracle querying if the user has obtained a certain role on Guild.
    /// @param addressToCheck The address of the user.
    /// @param roleId The id of the role that needs to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfilling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestGuildRoleCheck(
        address addressToCheck,
        uint256 roleId,
        bytes4 callbackFn,
        bytes memory args
    ) internal {
        requestOracle(
            addressToCheck,
            createMembershipUrl(addressToCheck),
            string.concat("role,", roleId.toString()),
            callbackFn,
            args
        );
    }

    /// @notice Sends a request to the oracle querying if the user has joined a certain guild.
    /// @param addressToCheck The address of the user.
    /// @param guildId The id of the guild that needs to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfilling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestGuildJoinCheck(
        address addressToCheck,
        uint256 guildId,
        bytes4 callbackFn,
        bytes memory args
    ) internal {
        requestOracle(
            addressToCheck,
            createMembershipUrl(addressToCheck),
            string.concat("guild,", guildId.toString()),
            callbackFn,
            args
        );
    }

    /// @notice Sends a request to the oracle querying if the user is an admin of a certain guild.
    /// @param addressToCheck The address of the user.
    /// @param guildId The id of the guild that needs to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfilling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestGuildAdminCheck(
        address addressToCheck,
        uint256 guildId,
        bytes4 callbackFn,
        bytes memory args
    ) internal {
        requestOracle(
            addressToCheck,
            createMembershipUrl(addressToCheck),
            string.concat("admin,", guildId.toString()),
            callbackFn,
            args
        );
    }

    /// @notice Sends a request to the oracle querying if the user is the owner of a certain guild.
    /// @param addressToCheck The address of the user.
    /// @param guildId The id of the guild that needs to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfilling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestGuildOwnerCheck(
        address addressToCheck,
        uint256 guildId,
        bytes4 callbackFn,
        bytes memory args
    ) internal {
        requestOracle(
            addressToCheck,
            createMembershipUrl(addressToCheck),
            string.concat("owner,", guildId.toString()),
            callbackFn,
            args
        );
    }

    function createMembershipUrl(address addressToCheck) private pure returns (string memory) {
        return
            string.concat("https://api.guild.xyz/v1/user/membership/", addressToCheck.toHexString(), "?format=oracle");
    }

    /// @notice Requests the needed data from the oracle.
    /// @dev Private function containing the logic of the other request...Check functions.
    /// @param addressToCheck The address of the user.
    /// @param path The path of the value that needs to be checked.
    /// @param callbackFn The identifier of the function the oracle should call when fulfilling the request.
    /// @param args Any additional function arguments in an abi encoded form.
    function requestOracle(
        address addressToCheck,
        string memory url,
        string memory path,
        bytes4 callbackFn,
        bytes memory args
    ) private {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), callbackFn);
        req.add("get", url);
        req.add("path", path);
        req.addInt("multiply", 1);
        bytes32 requestId = sendChainlinkRequest(req, oracleFee);

        RequestParams storage lastRequest = requests[requestId];
        lastRequest.userAddress = addressToCheck;
        lastRequest.args = args;
    }

    /// @notice Processes the data returned by the Chainlink node.
    /// @param requestId The id of the request.
    /// @param access The value returned by the oracle.
    modifier checkResponse(bytes32 requestId, uint256 access) {
        validateChainlinkCallback(requestId); // Same as the recordChainlinkFulfillment(requestId) modifier.

        RequestParams storage lastRequest = requests[requestId];

        if (access == uint256(Access.NO_ACCESS)) revert NoAccess(lastRequest.userAddress);
        if (access >= uint256(Access.CHECK_FAILED)) revert AccessCheckFailed(lastRequest.userAddress);

        emit HasAccess(lastRequest.userAddress);
        _;
    }
}
