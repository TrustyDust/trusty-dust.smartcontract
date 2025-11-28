// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Identity} from "./Identity.sol";
import {DustToken} from "./DustToken.sol";
import {SharedTypes} from "./SharedTypes.sol";
import {Errors} from "./Errors.sol";

/// @notice Core reward/tier logic with simplified access (no role functions).
contract Core {
    Identity public identity;
    DustToken public dust;

    // Rewards denominated in DUST (18 decimals)
    uint256 public likeReward = 1e18;
    uint256 public commentReward = 3e18;
    uint256 public repostReward = 1e18;

    event SocialRewarded(
        address indexed user,
        SharedTypes.SocialAction action,
        uint256 amount
    );
    event JobRewarded(address indexed user, uint8 rating, uint256 amount);

    constructor(Identity identity_, DustToken dust_) {
        identity = identity_;
        dust = dust_;
    }

    function rewardSocial(address user, uint8 actionType) external {
        if (user == address(0)) revert Errors.ZeroAddress();
        if (actionType > uint8(SharedTypes.SocialAction.REPOST)) revert Errors.InvalidInput();

        SharedTypes.SocialAction action = SharedTypes.SocialAction(actionType);
        uint256 delta = action == SharedTypes.SocialAction.LIKE
            ? likeReward
            : action == SharedTypes.SocialAction.COMMENT
            ? commentReward
            : repostReward;

        identity.addTrust(user, delta);
        dust.mint(user, delta);
        emit SocialRewarded(user, action, delta);
    }

    function rewardJob(address user, uint8 rating) external {
        if (user == address(0)) revert Errors.ZeroAddress();
        require(rating >= 1 && rating <= 5, "invalid rating");
        uint256 delta = rating == 5 ? 200e18 : rating == 4
            ? 150e18
            : rating == 3
            ? 100e18
            : rating == 2
            ? 50e18
            : 20e18;
        identity.addTrust(user, delta);
        identity.addJobCompleted(user);
        dust.mint(user, delta);
        emit JobRewarded(user, rating, delta);
    }
}
