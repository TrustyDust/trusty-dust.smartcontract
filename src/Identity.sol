// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SharedTypes} from "./SharedTypes.sol";

/// @notice Identity registry holding user state (trustScore, tier, reputation, posts, jobs). No role setter functions.
contract Identity {
    mapping(address => SharedTypes.User) public users;

    event TrustAdded(address indexed user, uint256 delta, uint256 newTrust);
    event TierSet(address indexed user, uint256 tier);
    event ReputationAdded(
        address indexed user,
        uint256 delta,
        uint256 newReputation
    );
    event PostAdded(address indexed user, uint256 totalPosts);
    event JobCompleted(address indexed user, uint256 totalJobsCompleted);

    function addTrust(address user, uint256 delta) external {
        users[user].trustScore += delta;
        emit TrustAdded(user, delta, users[user].trustScore);
    }

    function setTier(address user, uint256 tier) external {
        users[user].tier = tier;
        users[user].hasBadge = true;
        emit TierSet(user, tier);
    }

    function addReputation(address user, uint256 delta) external {
        users[user].reputation += delta;
        emit ReputationAdded(user, delta, users[user].reputation);
    }

    function addPost(address user) external {
        users[user].posts += 1;
        emit PostAdded(user, users[user].posts);
    }

    function addJobCompleted(address user) external {
        users[user].jobsCompleted += 1;
        emit JobCompleted(user, users[user].jobsCompleted);
    }
}
