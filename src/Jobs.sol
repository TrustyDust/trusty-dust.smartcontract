// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SharedTypes} from "./SharedTypes.sol";
import {Errors} from "./Errors.sol";
import {Identity} from "./Identity.sol";
import {DustToken} from "./DustToken.sol";
import {Core} from "./Core.sol";

/// @notice A job board that is also a soul-bound ERC721 token for each job.
contract Jobs is ERC721, Ownable {
    Identity public identity;
    DustToken public dust;
    Core public core;

    uint256 public constant JOB_FEE = 10e18; // 10 DUST

    // --- SBT State ---
    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenCIDs;
    uint256 public nextJobId = 1;

    // --- Job State ---
    mapping(uint256 => SharedTypes.Job) public jobs;

    event JobCreated(uint256 indexed jobId, address indexed poster, string cid, uint256 minScore, uint256 fee);
    event WorkerAssigned(uint256 indexed jobId, address indexed worker);
    event JobApproved(uint256 indexed jobId, address indexed worker, uint8 rating, uint256 rewardAmount);
    event JobCancelled(uint256 indexed jobId, address indexed poster);

    constructor(
        Identity identity_,
        DustToken dust_,
        Core core_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        identity = identity_;
        dust = dust_;
        core = core_;
        _baseTokenURI = baseURI_;
    }

    function createJob(uint256 minScore, string calldata cid) external returns (uint256 jobId) {
        if (minScore == 0) revert Errors.InvalidInput();

        // 1. Charge fee
        dust.burn(msg.sender, JOB_FEE);

        // 2. Mint the Soul-Bound Token internally
        jobId = nextJobId++;
        _safeMint(msg.sender, jobId);
        _tokenCIDs[jobId] = cid;
        
        // 3. Create the on-chain job
        jobs[jobId] = SharedTypes.Job({
            id: jobId,
            poster: msg.sender,
            worker: address(0),
            minScore: minScore,
            rating: 0,
            status: SharedTypes.JobStatus.OPEN
        });
        emit JobCreated(jobId, msg.sender, cid, minScore, JOB_FEE);
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

    function getJob(uint256 jobId) external view returns (SharedTypes.Job memory) {
        return jobs[jobId];
    }

    /// @notice Returns the full URI for a given token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseTokenURI, _tokenCIDs[tokenId]));
    }

    /// @dev Exposes the base URI used by the inherited ERC721 logic.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Makes the token soul-bound by preventing transfers after minting.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("SBT: Non-transferable token");
        }
        return super._update(to, tokenId, auth);
    }

    // --- Admin Functions ---

    /// @notice Sets the base URI for all token metadata.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }
}
