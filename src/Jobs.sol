// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SharedTypes} from "./SharedTypes.sol";
import {Errors} from "./Errors.sol";
import {Identity} from "./Identity.sol";
import {DustToken} from "./DustToken.sol";
import {Core} from "./Core.sol";

/// @notice Simplified job board with fee burn and reputational rewards.
contract Jobs {
    Identity public identity;
    DustToken public dust;
    Core public core;

    uint256 public constant JOB_FEE = 10e18; // 10 DUST (18 decimals)
    uint256 public nextJobId = 1;
    mapping(uint256 => SharedTypes.Job) public jobs;

    event JobCreated(uint256 indexed jobId, address indexed poster, uint256 minScore, uint256 fee);
    event WorkerAssigned(uint256 indexed jobId, address indexed worker);
    event JobApproved(uint256 indexed jobId, address indexed worker, uint8 rating, uint256 rewardAmount);
    event JobCancelled(uint256 indexed jobId, address indexed poster);

    constructor(Identity identity_, DustToken dust_, Core core_) {
        identity = identity_;
        dust = dust_;
        core = core_;
    }

    function createJob(uint256 minScore) external returns (uint256 jobId) {
        if (minScore == 0) revert Errors.InvalidInput();
        dust.burn(msg.sender, JOB_FEE);
        jobId = nextJobId++;
        jobs[jobId] = SharedTypes.Job({
            id: jobId,
            poster: msg.sender,
            worker: address(0),
            minScore: minScore,
            rating: 0,
            status: SharedTypes.JobStatus.OPEN
        });
        emit JobCreated(jobId, msg.sender, minScore, JOB_FEE);
    }

    function applyJob(uint256 jobId) external view {
        SharedTypes.Job storage j = jobs[jobId];
        if (j.id == 0) revert Errors.InvalidState();
        if (j.status != SharedTypes.JobStatus.OPEN) revert Errors.InvalidState();
    }

    function assignWorker(uint256 jobId, address worker) external {
        SharedTypes.Job storage j = jobs[jobId];
        if (j.poster != msg.sender) revert Errors.Unauthorized();
        if (j.status != SharedTypes.JobStatus.OPEN) revert Errors.InvalidState();
        j.worker = worker;
        emit WorkerAssigned(jobId, worker);
    }

    function approveJob(uint256 jobId, uint8 rating) external {
        SharedTypes.Job storage j = jobs[jobId];
        if (j.poster != msg.sender) revert Errors.Unauthorized();
        if (j.status != SharedTypes.JobStatus.OPEN) revert Errors.InvalidState();
        if (j.worker == address(0)) revert Errors.InvalidState();
        j.status = SharedTypes.JobStatus.COMPLETED;
        j.rating = rating;
        uint256 rewardAmount = _computeReward(rating);
        core.rewardJob(j.worker, rating);
        emit JobApproved(jobId, j.worker, rating, rewardAmount);
    }

    function cancelJob(uint256 jobId) external {
        SharedTypes.Job storage j = jobs[jobId];
        if (j.poster != msg.sender) revert Errors.Unauthorized();
        if (j.status != SharedTypes.JobStatus.OPEN) revert Errors.InvalidState();
        j.status = SharedTypes.JobStatus.CANCELLED;
        emit JobCancelled(jobId, j.poster);
    }

    function _computeReward(uint8 rating) internal pure returns (uint256) {
        if (rating == 5) return 200e18;
        if (rating == 4) return 150e18;
        if (rating == 3) return 100e18;
        if (rating == 2) return 50e18;
        return 20e18;
    }
}
