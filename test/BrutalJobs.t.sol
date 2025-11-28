// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Identity} from "src/Identity.sol";
import {DustToken} from "src/DustToken.sol";
import {Core} from "src/Core.sol";
import {Jobs} from "src/Jobs.sol";
import {Errors} from "src/Errors.sol";
import {SharedTypes} from "src/SharedTypes.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract BrutalJobsTest is Test {
    // Contracts
    Identity internal identity;
    DustToken internal dust;
    Core internal core;
    Jobs internal jobs;

    // Users
    address internal owner = address(this);
    address internal jobPoster;
    address internal worker;
    address internal attacker;

    // Constants
    uint256 internal constant JOB_FEE = 10e18;
    string internal constant BASE_URI = "https://ipfs.pinata.cloud/ipfs/";
    string internal constant TEST_CID = "Qm...test-cid";

    event JobCreated(uint256 indexed jobId, address indexed poster, string cid, uint256 minScore, uint256 fee);

    function setUp() public {
        // Deploy contracts
        identity = new Identity();
        dust = new DustToken("Dust", "DUST", owner);
        core = new Core(identity, dust);
        jobs = new Jobs(identity, dust, core, "JobSBT", "JOB", BASE_URI);

        // Setup roles
        dust.setRole(address(jobs), DustToken.Role.OPERATOR);
        dust.setRole(address(core), DustToken.Role.OPERATOR);

        // Define users
        jobPoster = address(0x10B);
        worker = address(0x20B);
        attacker = address(0xDEADBEEF);

        // Fund user
        dust.mint(jobPoster, 1000e18);
    }

    // ===================================================================
    // SECTION: BRUTAL - Dependency and State Machine Abuse
    // ===================================================================

    function test_Brutal_Revert_CreateJob_FailsIfJobsIsNotDustOperator() public {
        // Setup new Jobs contract without OPERATOR role on DustToken
        Jobs newJobs = new Jobs(identity, dust, core, "JobSBT", "JOB", BASE_URI);

        vm.prank(jobPoster);
        vm.expectRevert(Errors.Unauthorized.selector);
        newJobs.createJob(100, TEST_CID);
    }
    
    function test_Brutal_Revert_ApproveJob_BeforeWorkerAssigned() public {
        vm.prank(jobPoster);
        uint256 jobId = jobs.createJob(100, TEST_CID);

        vm.prank(jobPoster);
        vm.expectRevert(Errors.InvalidState.selector);
        jobs.approveJob(jobId, 5);
    }

    // =============================================
    // SECTION: ERC721 SBT Functionality Tests
    // =============================================

    function test_CreateJob_MintsSBTToPoster() public {
        vm.prank(jobPoster);
        uint256 jobId = jobs.createJob(100, TEST_CID);
        assertEq(jobs.ownerOf(jobId), jobPoster);
    }

    function test_TokenURI_IsCorrect() public {
        vm.prank(jobPoster);
        uint256 jobId = jobs.createJob(100, TEST_CID);
        string memory expectedURI = string(abi.encodePacked(BASE_URI, TEST_CID));
        assertTrue(
            keccak256(bytes(jobs.tokenURI(jobId))) == keccak256(bytes(expectedURI)),
            "Token URI is incorrect"
        );
    }

    function test_Revert_CannotTransferJobSBT() public {
        vm.prank(jobPoster);
        uint256 jobId = jobs.createJob(100, TEST_CID);

        vm.prank(jobPoster);
        vm.expectRevert(bytes("SBT: Non-transferable token"));
        jobs.transferFrom(jobPoster, attacker, jobId);
    }

    // =============================================
    // SECTION: Lifecycle & Input Validation Tests
    // =============================================

    function test_Successful_Lifecycle() public {
        // 1. Create Job
        vm.startPrank(jobPoster);
        vm.expectEmit(true, true, true, true);
        emit JobCreated(1, jobPoster, TEST_CID, 100, JOB_FEE);
        uint256 jobId = jobs.createJob(100, TEST_CID);
        vm.stopPrank();

        assertEq(jobId, 1);
        assertEq(dust.balanceOf(jobPoster), 1000e18 - JOB_FEE);
        assertEq(uint(jobs.getJob(jobId).status), uint(SharedTypes.JobStatus.OPEN));
        assertEq(jobs.ownerOf(jobId), jobPoster);

        // 2. Assign Worker
        vm.prank(jobPoster);
        jobs.assignWorker(jobId, worker);
        assertEq(jobs.getJob(jobId).worker, worker);

        // 3. Approve Job
        uint256 workerStartBalance = dust.balanceOf(worker);
        uint256 rewardAmount = 200e18; // rating 5

        vm.prank(jobPoster);
        jobs.approveJob(jobId, 5);

        // 4. Verify state
        assertEq(uint(jobs.getJob(jobId).status), uint(SharedTypes.JobStatus.COMPLETED));
        assertEq(jobs.getJob(jobId).rating, 5);
        assertEq(dust.balanceOf(worker), workerStartBalance + rewardAmount, "Worker reward incorrect");
    }

    function test_Revert_CreateJob_InsufficientBalance() public {
        vm.prank(attacker); // Attacker has 0 balance
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                attacker,
                0,
                JOB_FEE
            )
        );
        jobs.createJob(100, TEST_CID);
    }

    function test_Revert_CreateJob_ZeroMinScore() public {
        vm.prank(jobPoster);
        vm.expectRevert(Errors.InvalidInput.selector);
        jobs.createJob(0, TEST_CID);
    }

    function test_Revert_ApproveJob_InvalidRating() public {
        vm.prank(jobPoster);
        uint256 jobId = jobs.createJob(100, TEST_CID);
        vm.prank(jobPoster);
        jobs.assignWorker(jobId, worker);

        vm.prank(jobPoster);
        vm.expectRevert(bytes("invalid rating")); // Revert from Core contract
        jobs.approveJob(jobId, 6);
    }
}
