// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Identity} from "src/Identity.sol";
import {DustToken} from "src/DustToken.sol";
import {Core} from "src/Core.sol";
import {SharedTypes} from "src/SharedTypes.sol";
import {Errors} from "src/Errors.sol";

contract BrutalCoreTest is Test {
    Identity internal identity;
    DustToken internal dust;
    Core internal core;

    address internal owner = address(this);
    address internal user = address(0xABC);
    address internal attacker = address(0xDEADBEEF);

    event SocialRewarded(address indexed user, SharedTypes.SocialAction action, uint256 amount);

    function setUp() public {
        // Deploy semua kontrak dependen
        identity = new Identity();
        dust = new DustToken("Dust", "DUST", owner);
        core = new Core(identity, dust);

        // KRUSIAL: Memberikan Core contract peran OPERATOR di DustToken agar bisa melakukan mint.
        dust.setRole(address(core), DustToken.Role.OPERATOR);
    }

    // ===================================================================
    // SECTION: BRUTAL - Open Access & Dependency Failure Tests
    // ===================================================================

    function test_Brutal_AttackerCanGrantThemselvesEndlessSocialRewards() public {
        uint256 startTrust = identity.getUser(attacker).trustScore;
        uint256 startBalance = dust.balanceOf(attacker);
        uint256 expectedReward = core.commentReward(); // Reward terbesar

        vm.startPrank(attacker);
        for (uint i = 0; i < 10; i++) {
            core.rewardSocial(attacker, 1); // Memberi reward 'COMMENT' pada diri sendiri
        }
        vm.stopPrank();

        assertEq(identity.getUser(attacker).trustScore, startTrust + (expectedReward * 10));
        assertEq(dust.balanceOf(attacker), startBalance + (expectedReward * 10));
    }

    function test_Brutal_AttackerCanGrantAnyoneEndlessJobRewards() public {
        uint256 startTrust = identity.getUser(user).trustScore;
        uint256 startBalance = dust.balanceOf(user);
        uint256 startJobs = identity.getUser(user).jobsCompleted;
        uint256 rating5reward = 200e18; // Hardcoded from contract logic

        vm.startPrank(attacker);
        core.rewardJob(user, 5);
        vm.stopPrank();

        assertEq(identity.getUser(user).trustScore, startTrust + rating5reward);
        assertEq(dust.balanceOf(user), startBalance + rating5reward);
        assertEq(identity.getUser(user).jobsCompleted, startJobs + 1);
    }

    function test_Brutal_Revert_MintFailsIfCoreIsNotOperator() public {
        // Setup baru tanpa memberikan peran OPERATOR
        Identity newIdentity = new Identity();
        DustToken newDust = new DustToken("Dust", "DUST", owner);
        Core newCore = new Core(newIdentity, newDust);

        // Panggil rewardSocial, ini akan revert di dalam DustToken karena newCore bukan operator
        // Pesan error Unauthorized() berasal dari DustToken
        vm.expectRevert(Errors.Unauthorized.selector);
        newCore.rewardSocial(user, 0);
    }

    // =============================================
    // SECTION: rewardSocial Tests
    // =============================================

    function test_RewardSocial_Like() public {
        uint256 reward = core.likeReward();
        vm.expectEmit(true, true, true, true);
        emit SocialRewarded(user, SharedTypes.SocialAction.LIKE, reward);
        core.rewardSocial(user, uint8(SharedTypes.SocialAction.LIKE));
        assertEq(identity.getUser(user).trustScore, reward);
        assertEq(dust.balanceOf(user), reward);
    }

    function test_RewardSocial_Comment() public {
        uint256 reward = core.commentReward();
        vm.expectEmit(true, true, true, true);
        emit SocialRewarded(user, SharedTypes.SocialAction.COMMENT, reward);
        core.rewardSocial(user, uint8(SharedTypes.SocialAction.COMMENT));
        assertEq(identity.getUser(user).trustScore, reward);
        assertEq(dust.balanceOf(user), reward);
    }
    
    function test_Edge_InvalidSocialActionDefaultsToRepostReward() public {
        uint8 invalidActionType = 3; // Tidak ada di enum SocialAction

        vm.expectRevert(Errors.InvalidInput.selector);
        core.rewardSocial(user, invalidActionType);
    }

    function test_RewardSocial_OnZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        core.rewardSocial(address(0), 0);
    }

    // =============================================
    // SECTION: rewardJob Tests
    // =============================================

    function test_RewardJob_AllRatings() public {
        uint256[] memory rewards = new uint256[](5);
        rewards[0] = 20e18;  // Rating 1
        rewards[1] = 50e18;  // Rating 2
        rewards[2] = 100e18; // Rating 3
        rewards[3] = 150e18; // Rating 4
        rewards[4] = 200e18; // Rating 5

        for (uint8 i = 1; i <= 5; i++) {
            address testUser = address(uint160(i));
            core.rewardJob(testUser, i);
            uint256 totalTrust = rewards[i-1];
            assertEq(identity.getUser(testUser).trustScore, totalTrust, "Trust score mismatch for rating");
            assertEq(dust.balanceOf(testUser), totalTrust, "Dust balance mismatch for rating");
            assertEq(identity.getUser(testUser).jobsCompleted, 1, "Job count should be 1");
        }
    }

    function test_Revert_RewardJob_InvalidRating_Zero() public {
        vm.expectRevert(bytes("invalid rating"));
        core.rewardJob(user, 0);
    }

    function test_Revert_RewardJob_InvalidRating_Above5() public {
        vm.expectRevert(bytes("invalid rating"));
        core.rewardJob(user, 6);
    }

    function test_RewardJob_OnZeroAddress() public {
         vm.expectRevert(Errors.ZeroAddress.selector);
         core.rewardJob(address(0), 3);
    }
}
