// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Identity} from "src/Identity.sol";
import {Verifier, IExternalVerifier} from "src/Verifier.sol";
import {Errors} from "src/Errors.sol";

// =============================================
// SECTION: Mock & Malicious Verifier Contracts
// =============================================
contract MockVerifier is IExternalVerifier {
    bool private _shouldPass;

    function setShouldPass(bool shouldPass) external {
        _shouldPass = shouldPass;
    }

    function verify(bytes calldata, bytes32[] calldata) external view returns (bool) {
        return _shouldPass;
    }
}

contract MaliciousVerifier is IExternalVerifier {
    // Verifier berbahaya ini selalu mengembalikan 'true' untuk setiap bukti.
    function verify(bytes calldata, bytes32[] calldata) external pure returns (bool) {
        return true;
    }
}


// =============================================
// SECTION: Brutal Verifier Test
// =============================================
contract BrutalVerifierTest is Test {
    Identity internal identity;
    Verifier internal verifier;
    MockVerifier internal mockScoreVerifier;
    MockVerifier internal mockTierVerifier;
    
    address internal user = address(0xABC);
    address internal attacker = address(0xDEADBEEF);

    function setUp() public {
        identity = new Identity();
        verifier = new Verifier(identity);
        mockScoreVerifier = new MockVerifier();
        mockTierVerifier = new MockVerifier();

        // Konfigurasi awal yang benar
        verifier.setVerifiers(address(mockScoreVerifier), address(mockTierVerifier));
    }

    // ===================================================================
    // SECTION: BRUTAL - Malicious Verifier Injection Attack
    // ===================================================================

    function test_Brutal_AttackerCanSetVerifiers() public {
        vm.prank(attacker);
        verifier.setVerifiers(attacker, attacker); // Attacker menunjuk verifier ke dirinya sendiri
        assertEq(address(verifier.trustScoreVerifier()), attacker);
        assertEq(address(verifier.tierVerifier()), attacker);
    }

    function test_Brutal_AttackerCanUseMaliciousVerifierToSetOwnTier() public {
        // 1. Deploy verifier berbahaya
        MaliciousVerifier malicious = new MaliciousVerifier();
        
        // 2. Attacker memanggil setVerifiers untuk menunjuk ke kontrak berbahayanya
        vm.prank(attacker);
        verifier.setVerifiers(address(mockScoreVerifier), address(malicious));

        // 3. Attacker sekarang memanggil verifyTier dengan bukti palsu ("0x")
        uint256 targetTier = 5;
        uint256 fakeTrustScore = 1_000_000e18;
        assertEq(identity.getUser(attacker).tier, 0, "Attacker tier should be 0 initially");

        vm.prank(attacker);
        bool result = verifier.verifyTier("0x", targetTier, fakeTrustScore);

        // 4. Verifikasi serangan berhasil
        assertTrue(result, "Verification should pass due to malicious verifier");
        assertEq(identity.getUser(attacker).tier, targetTier, "Attacker should have successfully set their tier");
        assertTrue(identity.getUser(attacker).hasBadge, "Attacker should have a badge");
    }

    // =============================================
    // SECTION: State & Initialization Tests
    // =============================================

    function test_Revert_VerifyFailsIfVerifierNotSet() public {
        Verifier newVerifier = new Verifier(identity); // Belum di-set
        vm.expectRevert(Errors.InvalidState.selector);
        newVerifier.verifyTrustScore("0x", 100);
        
        vm.expectRevert(Errors.InvalidState.selector);
        newVerifier.verifyTier("0x", 1, 100);
    }
    
    // =============================================
    // SECTION: verifyTrustScore Tests
    // =============================================

    function test_VerifyTrustScore_Success() public {
        mockScoreVerifier.setShouldPass(true);
        bool result = verifier.verifyTrustScore("0x", 100);
        assertTrue(result);
    }

    function test_VerifyTrustScore_Failure() public {
        mockScoreVerifier.setShouldPass(false);
        bool result = verifier.verifyTrustScore("0x", 100);
        assertFalse(result);
    }

    // =============================================
    // SECTION: verifyTier Tests
    // =============================================

    function test_VerifyTier_Success_SetsIdentityTier() public {
        mockTierVerifier.setShouldPass(true);
        uint256 startTier = identity.getUser(user).tier;
        assertEq(startTier, 0);

        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit Verifier.TierVerified(user, 3, 500, true);
        bool result = verifier.verifyTier("0x", 3, 500);

        assertTrue(result);
        assertEq(identity.getUser(user).tier, 3, "User tier should be updated");
        assertTrue(identity.getUser(user).hasBadge, "User should have a badge after tier set");
    }

    function test_VerifyTier_Failure_DoesNotSetIdentityTier() public {
        mockTierVerifier.setShouldPass(false);
        uint256 startTier = identity.getUser(user).tier;
        assertEq(startTier, 0);

        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit Verifier.TierVerified(user, 3, 500, false);
        bool result = verifier.verifyTier("0x", 3, 500);

        assertFalse(result);
        assertEq(identity.getUser(user).tier, startTier, "User tier should NOT be updated");
        assertFalse(identity.getUser(user).hasBadge);
    }
}
