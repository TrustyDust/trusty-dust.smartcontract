// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Identity} from "src/Identity.sol";
import {SharedTypes} from "src/SharedTypes.sol";

contract BrutalIdentityTest is Test {
    Identity internal identity;

    address internal user1 = address(0xA1);
    address internal user2 = address(0xB1);
    address internal randomAttacker = address(0xDEADBEEF);

    function setUp() public {
        identity = new Identity();
    }

    // ===============================================================
    // SECTION: BRUTAL - Open Access Vulnerability Tests
    // Tes ini membuktikan bahwa siapa pun bisa memanipulasi data siapa pun.
    // ===============================================================

    function test_Brutal_AttackerCanAddTrustToAnyone() public {
        uint256 startTrust = identity.getUser(user1).trustScore;
        uint256 fakeTrust = 1_000_000e18;

        vm.prank(randomAttacker);
        identity.addTrust(user1, fakeTrust);

        assertEq(identity.getUser(user1).trustScore, startTrust + fakeTrust, "Attacker should be able to inflate trust score");
    }

    function test_Brutal_AttackerCanSetAnyoneTier() public {
        uint256 targetTier = 5; // Tier tertinggi
        assertFalse(identity.getUser(user1).hasBadge);

        vm.prank(randomAttacker);
        identity.setTier(user1, targetTier);

        assertEq(identity.getUser(user1).tier, targetTier, "Attacker should be able to set any tier");
        assertTrue(identity.getUser(user1).hasBadge, "Attacker should be able to grant a badge");
    }
    
    function test_Brutal_AttackerCanAddReputationToAnyone() public {
        uint256 startRep = identity.getUser(user2).reputation;
        uint256 fakeRep = 999e18;

        vm.prank(randomAttacker);
        identity.addReputation(user2, fakeRep);

        assertEq(identity.getUser(user2).reputation, startRep + fakeRep, "Attacker should be able to inflate reputation");
    }

    function test_Brutal_AttackerCanFalsifyPostCount() public {
        uint256 startPosts = identity.getUser(user1).posts;
        
        vm.startPrank(randomAttacker);
        for(uint i=0; i<100; ++i) {
            identity.addPost(user1);
        }
        vm.stopPrank();

        assertEq(identity.getUser(user1).posts, startPosts + 100, "Attacker should be able to fake post counts");
    }

    function test_Brutal_AttackerCanFalsifyJobCount() public {
        uint256 startJobs = identity.getUser(user2).jobsCompleted;
        
        vm.prank(randomAttacker);
        identity.addJobCompleted(user2);

        assertEq(identity.getUser(user2).jobsCompleted, startJobs + 1, "Attacker should be able to fake job completion");
    }

    // =============================================
    // SECTION: Zero Address Input Tests
    // =============================================

    function test_Edge_CanModifyStateForZeroAddress() public {
        uint256 delta = 123;
        
        // Trust
        identity.addTrust(address(0), delta);
        assertEq(identity.getUser(address(0)).trustScore, delta);

        // Tier
        identity.setTier(address(0), 2);
        assertEq(identity.getUser(address(0)).tier, 2);
        assertTrue(identity.getUser(address(0)).hasBadge);

        // Reputation
        identity.addReputation(address(0), delta);
        assertEq(identity.getUser(address(0)).reputation, delta);

        // Posts
        identity.addPost(address(0));
        assertEq(identity.getUser(address(0)).posts, 1);

        // Jobs
        identity.addJobCompleted(address(0));
        assertEq(identity.getUser(address(0)).jobsCompleted, 1);
    }

    // =============================================
    // SECTION: Standard Logic and Event Tests
    // =============================================

    function test_AddTrust_CorrectlyIncrementsAndEmitsEvent() public {
        uint256 startTrust = identity.getUser(user1).trustScore;
        uint256 delta = 100e18;
        
        vm.expectEmit(true, false, false, true);
        emit Identity.TrustAdded(user1, delta, startTrust + delta);
        identity.addTrust(user1, delta);
        
        assertEq(identity.getUser(user1).trustScore, startTrust + delta);
    }

    function test_SetTier_CorrectlySetsAndEmitsEvent() public {
        uint256 newTier = 3;

        vm.expectEmit(true, false, false, true);
        emit Identity.TierSet(user1, newTier);
        identity.setTier(user1, newTier);

        assertEq(identity.getUser(user1).tier, newTier);
        assertTrue(identity.getUser(user1).hasBadge);
    }

    function test_AddReputation_CorrectlyIncrementsAndEmitsEvent() public {
        uint256 startRep = identity.getUser(user1).reputation;
        uint256 delta = 50;

        vm.expectEmit(true, false, false, true);
        emit Identity.ReputationAdded(user1, delta, startRep + delta);
        identity.addReputation(user1, delta);

        assertEq(identity.getUser(user1).reputation, startRep + delta);
    }

    function test_AddPost_CorrectlyIncrementsAndEmitsEvent() public {
        uint256 startPosts = identity.getUser(user1).posts;

        vm.expectEmit(true, false, false, true);
        emit Identity.PostAdded(user1, startPosts + 1);
        identity.addPost(user1);

        assertEq(identity.getUser(user1).posts, startPosts + 1);
    }

    function test_AddJobCompleted_CorrectlyIncrementsAndEmitsEvent() public {
        uint256 startJobs = identity.getUser(user1).jobsCompleted;

        vm.expectEmit(true, false, false, true);
        emit Identity.JobCompleted(user1, startJobs + 1);
        identity.addJobCompleted(user1);

        assertEq(identity.getUser(user1).jobsCompleted, startJobs + 1);
    }

    // =============================================
    // SECTION: Edge Case Tests
    // =============================================

    function test_AddTrust_WithZeroDelta() public {
        uint256 startTrust = identity.getUser(user1).trustScore;
        
        vm.expectEmit(true, false, false, true);
        emit Identity.TrustAdded(user1, 0, startTrust);
        identity.addTrust(user1, 0);

        assertEq(identity.getUser(user1).trustScore, startTrust);
    }

    function test_SetTier_CanBeOverwritten() public {
        identity.setTier(user1, 2);
        assertEq(identity.getUser(user1).tier, 2);

        identity.setTier(user1, 4);
        assertEq(identity.getUser(user1).tier, 4);
    }
    
    function test_Revert_AddTrustOverflow() public {
        uint256 hugeAmount = type(uint256).max;
        identity.addTrust(user1, 100);

        vm.expectRevert();
        identity.addTrust(user1, hugeAmount);
    }
}
