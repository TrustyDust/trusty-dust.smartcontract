// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseTest} from "./Base.t.sol";
import {DustToken} from "src/DustToken.sol";
import {Errors} from "src/Errors.sol";

contract BrutalDustTokenTest is BaseTest {
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Alamat-alamat untuk pengujian yang lebih jelas
    address internal owner;
    address internal designatedOperator;
    address internal randomUser;

    // Pesan error khusus dari kontrak
    string internal constant NON_TRANSFERABLE_ERROR = "DUST: NON TRANSFERABLE";

    function setUp() public override {
        // Kita tidak memanggil super.setUp() agar bisa mengontrol state awal secara penuh
        owner = address(this);
        designatedOperator = address(0x02A);
        randomUser = address(0xBAD);

        // Deploy kontrak DustToken dengan test contract ini sebagai owner
        dust = new DustToken("Dust", "DUST", owner);

        // Memberikan peran OPERATOR ke alamat yang sudah ditentukan
        dust.setRole(designatedOperator, DustToken.Role.OPERATOR);

        // Memberi modal awal untuk pengujian burn dan transfer
        dust.mint(randomUser, 1000e18);
    }

    // =============================================
    // SECTION: Constructor & Deployment Tests
    // =============================================

    function test_Revert_DeployWithZeroAddressOwner() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new DustToken("Dust", "DUST", address(0));
    }

    function test_Deployment_SetsCorrectOwner() public view {
        assertEq(uint(dust.roles(owner)), uint(DustToken.Role.OWNER));
    }

    // =============================================
    // SECTION: Role Management (setRole) Tests
    // =============================================

    function test_OwnerCanSetRole() public {
        assertEq(uint(dust.roles(user1)), uint(DustToken.Role.NONE));
        dust.setRole(user1, DustToken.Role.SYSTEM);
        assertEq(uint(dust.roles(user1)), uint(DustToken.Role.SYSTEM));
    }

    function test_OwnerCanOverwriteExistingRole() public {
        dust.setRole(user1, DustToken.Role.OPERATOR);
        assertEq(uint(dust.roles(user1)), uint(DustToken.Role.OPERATOR));

        dust.setRole(user1, DustToken.Role.SYSTEM);
        assertEq(uint(dust.roles(user1)), uint(DustToken.Role.SYSTEM));
    }

    function test_Revert_NonOwnerCannotSetRole() public {
        vm.startPrank(randomUser);
        vm.expectRevert(Errors.Unauthorized.selector);
        dust.setRole(user2, DustToken.Role.OPERATOR);
        vm.stopPrank();
    }

    function test_Revert_OperatorCannotSetRole() public {
        vm.startPrank(designatedOperator);
        vm.expectRevert(Errors.Unauthorized.selector);
        dust.setRole(user2, DustToken.Role.OPERATOR);
        vm.stopPrank();
    }

    function test_Revert_SetRoleForZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        dust.setRole(address(0), DustToken.Role.OPERATOR);
    }

    // =============================================
    // SECTION: Minting Tests
    // =============================================

    function test_OwnerCanMint() public {
        uint256 startBalance = dust.balanceOf(user1);
        uint256 mintAmount = 500e18;

        dust.mint(user1, mintAmount);

        assertEq(dust.balanceOf(user1), startBalance + mintAmount);
    }

    function test_Event_MintEmitsTransfer() public {
        uint256 mintAmount = 1e18;
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user1, mintAmount);
        dust.mint(user1, mintAmount);
    }

    function test_Revert_MintToZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        dust.mint(address(0), 100e18);
    }

    function test_Revert_MintZeroAmount() public {
        vm.expectRevert(Errors.ZeroAmount.selector);
        dust.mint(user1, 0);
    }

    function test_Revert_RandomUserCannotMint() public {
        vm.prank(randomUser);
        vm.expectRevert(Errors.Unauthorized.selector);
        dust.mint(randomUser, 100e18);
    }

    function test_OperatorCanMint() public {
        uint256 startBalance = dust.balanceOf(designatedOperator);
        uint256 mintAmount = 100e18;

        vm.startPrank(designatedOperator);
        dust.mint(designatedOperator, mintAmount);
        vm.stopPrank();

        assertEq(dust.balanceOf(designatedOperator), startBalance + mintAmount);
    }

    // =============================================
    // SECTION: Burning Tests
    // =============================================

    function test_OwnerCanBurn() public {
        uint256 startBalance = dust.balanceOf(randomUser);
        uint256 burnAmount = 300e18;
        assertTrue(startBalance >= burnAmount);

        dust.burn(randomUser, burnAmount);

        assertEq(dust.balanceOf(randomUser), startBalance - burnAmount);
    }

    function test_OwnerCanBurnOwnTokens() public {
        uint256 mintAmount = 100e18;
        dust.mint(owner, mintAmount);
        assertEq(dust.balanceOf(owner), mintAmount);

        dust.burn(owner, mintAmount);
        assertEq(dust.balanceOf(owner), 0);
    }

    function test_Event_BurnEmitsTransfer() public {
        uint256 burnAmount = 1e18;
        vm.expectEmit(true, true, true, true);
        emit Transfer(randomUser, address(0), burnAmount);
        dust.burn(randomUser, burnAmount);
    }

    function test_Revert_BurnFromZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        dust.burn(address(0), 100e18);
    }

    function test_Revert_BurnZeroAmount() public {
        vm.expectRevert(Errors.ZeroAmount.selector);
        dust.burn(randomUser, 0);
    }

    function test_Revert_BurnMoreThanBalance() public {
        uint256 balance = dust.balanceOf(randomUser);
        vm.expectRevert(); // ERC20: burn amount exceeds balance
        dust.burn(randomUser, balance + 1);
    }

    function test_Revert_RandomUserCannotBurnOwnTokens() public {
        vm.startPrank(randomUser);
        vm.expectRevert(Errors.Unauthorized.selector);
        dust.burn(randomUser, 1e18); // Coba bakar token sendiri
        vm.stopPrank();
    }

    function test_Revert_RandomUserCannotBurnOtherTokens() public {
        dust.mint(user1, 100e18);
        vm.startPrank(randomUser);
        vm.expectRevert(Errors.Unauthorized.selector);
        dust.burn(user1, 1e18); // Coba bakar token orang lain
        vm.stopPrank();
    }

    function test_OperatorCanBurn() public {
        uint256 startBalance = dust.balanceOf(randomUser);
        uint256 burnAmount = 100e18;

        vm.startPrank(designatedOperator);
        dust.burn(randomUser, burnAmount);
        vm.stopPrank();

        assertEq(dust.balanceOf(randomUser), startBalance - burnAmount);
    }

    // =============================================
    // SECTION: Transfer Logic (NON-TRANSFERABLE) Tests
    // =============================================

    function test_Revert_TransferIsBlocked() public {
        uint256 balance = dust.balanceOf(randomUser);
        assertTrue(balance > 0);

        vm.startPrank(randomUser);
        vm.expectRevert(bytes(NON_TRANSFERABLE_ERROR));
        dust.transfer(user1, 100e18);
        vm.stopPrank();
    }

    function test_Revert_SelfTransferIsBlocked() public {
        vm.startPrank(randomUser);
        vm.expectRevert(bytes(NON_TRANSFERABLE_ERROR));
        dust.transfer(randomUser, 100e18);
        vm.stopPrank();
    }

    // Bahkan owner tidak bisa melakukan transfer normal
    function test_Revert_OwnerTransferIsBlocked() public {
        dust.mint(owner, 100e18);
        vm.expectRevert(bytes(NON_TRANSFERABLE_ERROR));
        dust.transfer(user1, 100e18);
    }

    // Approve seharusnya tetap berfungsi, meskipun transferFrom diblokir
    function test_ApproveStillWorks() public {
        uint256 approveAmount = 100e18;
        vm.prank(randomUser);
        dust.approve(designatedOperator, approveAmount);
        assertEq(dust.allowance(randomUser, designatedOperator), approveAmount);
    }

    function test_Revert_TransferFromIsBlocked() public {
        uint256 approveAmount = 100e18;

        // randomUser menyetujui operator untuk mengambil tokennya
        vm.startPrank(randomUser);
        dust.approve(designatedOperator, approveAmount);
        vm.stopPrank();

        // operator mencoba mengambil token tsb, seharusnya gagal
        vm.startPrank(designatedOperator);
        vm.expectRevert(bytes(NON_TRANSFERABLE_ERROR));
        dust.transferFrom(randomUser, designatedOperator, approveAmount);
        vm.stopPrank();
    }
}
