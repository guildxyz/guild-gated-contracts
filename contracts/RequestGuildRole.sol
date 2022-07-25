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
        address userAddress;
        uint256 roleId;
        bytes functionToCall;
    }

    struct Result {
        address userAddress;
        uint248 roleId;
        bool access;
    }

    mapping(bytes32 => RequestParams) public requests;
    mapping(bytes32 => Result) public results;

    // 0.05 LINK (0.07 for Polygon Mainnet)
    uint256 private constant ORACLE_FEE = ((1 * LINK_DIVISIBILITY) / 100) * 5;
    bytes32 private constant JOB_ID = "a56c23c069b446a5bfd3b5fc91383991";

    error DelegatecallReverted();

    event HasRole(address userAddress, uint256 roleId, bool access);

    constructor() {
        // RINKEBY
        setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        setChainlinkOracle(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434);
    }

    /// @notice Request the needed data from the oracle.
    /// @param userAddress The address of the user.
    /// @param guildIndex The index of the guild from the membership endpoint, starting from 0.
    /// @param roleId The roleId that has to be checked.
    /// @param functionToCall The encoded calldata of the function the oracle will call on fulfillment.
    function requestAccessCheck(
        address userAddress,
        uint256 guildIndex,
        uint256 roleId,
        bytes memory functionToCall
    ) public {
        Chainlink.Request memory req = buildChainlinkRequest(JOB_ID, address(this), this.fulfillRoleCheck.selector);
        req.add("get", string.concat("https://api.guild.xyz/v1/user/membership/", userAddress.toHexString()));
        req.add("path", string.concat(guildIndex.toString(), ",roleIds"));
        bytes32 requestId = sendOperatorRequest(req, ORACLE_FEE);

        RequestParams storage lastRequest = requests[requestId];
        lastRequest.userAddress = userAddress;
        lastRequest.roleId = roleId;
        lastRequest.functionToCall = functionToCall;
    }

    /// @dev The function called by the Chainlink node returning the data.
    function fulfillRoleCheck(bytes32 requestId, uint256[] memory returnedArray) public {
        RequestParams storage lastRequest = requests[requestId];
        Result storage lastResult = results[requestId];

        uint256 wantThisRole = lastRequest.roleId;
        lastResult.roleId = uint248(wantThisRole);

        address userAddress = lastRequest.userAddress;
        lastResult.userAddress = userAddress;

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

        lastResult.access = access;
        emit HasRole(userAddress, wantThisRole, access);

        if (access) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = address(this).delegatecall(lastRequest.functionToCall);
            if (!success) {
                if (returndata.length > 0) {
                    // If there is a revert reason, get it.
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert DelegatecallReverted();
                }
            }
        }
    }
}
