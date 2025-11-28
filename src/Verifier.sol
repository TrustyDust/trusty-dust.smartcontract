// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Identity} from "./Identity.sol";
import {Errors} from "./Errors.sol";

/// @notice Simple wrapper around external verifier; assumes external call off-chain simulated here.
interface IExternalVerifier {
    function verify(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external view returns (bool);
}

contract Verifier {
    Identity public identity;
    IExternalVerifier public trustScoreVerifier;
    IExternalVerifier public tierVerifier;

    event VerifiersSet(
        address indexed trustScoreVerifier,
        address indexed tierVerifier
    );
    event TrustScoreVerified(
        address indexed user,
        uint256 minScore,
        bool passed
    );
    event TierVerified(
        address indexed user,
        uint256 tier,
        uint256 trustScore,
        bool passed
    );

    constructor(Identity identity_) {
        identity = identity_;
    }

    function setVerifiers(address score, address tier) external {
        trustScoreVerifier = IExternalVerifier(score);
        tierVerifier = IExternalVerifier(tier);
        emit VerifiersSet(score, tier);
    }

    function verifyTrustScore(
        bytes calldata proof,
        uint256 minScore
    ) external returns (bool) {
        bytes32[] memory pubInputs = new bytes32[](2);
        pubInputs[0] = bytes32(uint256(uint160(msg.sender)));
        pubInputs[1] = bytes32(minScore);
        if (address(trustScoreVerifier) == address(0))
            revert Errors.InvalidState();

        bool ok = trustScoreVerifier.verify(proof, pubInputs);
        emit TrustScoreVerified(msg.sender, minScore, ok);
        return ok;
    }

    function verifyTier(
        bytes calldata proof,
        uint256 tier,
        uint256 trustScore
    ) external returns (bool) {
        bytes32[] memory pubInputs = new bytes32[](3);
        pubInputs[0] = bytes32(uint256(uint160(msg.sender)));
        pubInputs[1] = bytes32(tier);
        pubInputs[2] = bytes32(trustScore);
        if (address(tierVerifier) == address(0)) revert Errors.InvalidState();
        bool ok = tierVerifier.verify(proof, pubInputs);
        if (ok) {
            identity.setTier(msg.sender, tier);
        }
        emit TierVerified(msg.sender, tier, trustScore, ok);
        return ok;
    }
}
