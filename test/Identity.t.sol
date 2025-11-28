// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Identity} from "src/Identity.sol";
import {SharedTypes} from "src/SharedTypes.sol";

contract IdentityTest is Test {
    Identity internal identity;
    address internal user = address(0xA11CE);

    function setUp() public {
        identity = new Identity();
    }

    function testAddTrustAndTier() public {
        identity.addTrust(user, 10);
        identity.setTier(user, 2);
        SharedTypes.User memory u = identity.getUser(user);
        assertEq(u.trustScore, 10);
        assertEq(u.tier, 2);
        assertTrue(u.hasBadge);
    }

    function testReputationPostsJobs() public {
        identity.addReputation(user, 5);
        identity.addPost(user);
        identity.addJobCompleted(user);
        SharedTypes.User memory u2 = identity.getUser(user);
        assertEq(u2.reputation, 5);
        assertEq(u2.posts, 1);
        assertEq(u2.jobsCompleted, 1);
    }
}
