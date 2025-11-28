// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Identity} from "src/Identity.sol";
import {DustToken} from "src/DustToken.sol";
import {Content} from "src/Content.sol";
import {Errors} from "src/Errors.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract BrutalContentTest is Test {
    // Contracts
    Identity internal identity;
    DustToken internal dust;
    Content internal content;

    // Users
    address internal owner = address(this);
    address internal userWithFunds;
    address internal userWithoutFunds;
    address internal attacker;

    // Constants
    uint256 internal constant POST_FEE = 10e18;
    string internal constant BASE_URI = "https://ipfs.pinata.cloud/ipfs/";
    string internal constant TEST_CID = "Qm...content-cid";

    event PostMinted(address indexed user, uint256 indexed tokenId, string cid, uint256 fee);

    function setUp() public {
        // Define users
        userWithFunds = address(0xABC);
        userWithoutFunds = address(0xDEF);
        attacker = address(0xBAD);

        // Deploy contracts
        identity = new Identity();
        dust = new DustToken("Dust", "DUST", owner);
        content = new Content(identity, dust, "ContentSBT", "POST", BASE_URI);

        // Setup roles
        dust.setRole(address(content), DustToken.Role.OPERATOR);

        // Fund users
        dust.mint(userWithFunds, 100e18);
        dust.mint(userWithoutFunds, POST_FEE - 1);
    }

    // ===================================================================
    // SECTION: BRUTAL - Dependency & Financial Failure Tests
    // ===================================================================

    function test_Brutal_Revert_MintPost_FailsIfContentIsNotDustOperator() public {
        Content newContent = new Content(identity, dust, "SBT", "S", BASE_URI);
        
        vm.prank(userWithFunds);
        vm.expectRevert(Errors.Unauthorized.selector);
        newContent.mintPost(TEST_CID);
    }

    function test_Revert_MintPost_InsufficientBalance() public {
        uint256 balance = dust.balanceOf(userWithoutFunds);
        vm.prank(userWithoutFunds);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                userWithoutFunds,
                balance,
                POST_FEE
            )
        );
        content.mintPost(TEST_CID);
    }
    
    function test_Revert_MintPost_ZeroBalance() public {
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                attacker,
                0,
                POST_FEE
            )
        );
        content.mintPost(TEST_CID);
    }

    // =============================================
    // SECTION: ERC721 SBT Functionality Tests
    // =============================================

     function test_CreatePost_MintsSBTToPoster() public {
        vm.prank(userWithFunds);
        uint256 tokenId = content.mintPost(TEST_CID);
        assertEq(content.ownerOf(tokenId), userWithFunds);
    }

    function test_TokenURI_IsCorrect() public {
        vm.prank(userWithFunds);
        uint256 tokenId = content.mintPost(TEST_CID);
        string memory expectedURI = string(abi.encodePacked(BASE_URI, TEST_CID));
        assertTrue(
            keccak256(bytes(content.tokenURI(tokenId))) == keccak256(bytes(expectedURI)),
            "Token URI is incorrect"
        );
    }

    function test_Revert_CannotTransferContentSBT() public {
        vm.prank(userWithFunds);
        uint256 tokenId = content.mintPost(TEST_CID);

        vm.prank(userWithFunds);
        vm.expectRevert(bytes("SBT: Non-transferable token"));
        content.transferFrom(userWithFunds, attacker, tokenId);
    }

    // =============================================
    // SECTION: Standard Functionality Tests
    // =============================================

    function test_MintPost_Success() public {
        uint256 startBalance = dust.balanceOf(userWithFunds);
        uint256 startPosts = identity.getUser(userWithFunds).posts;

        vm.startPrank(userWithFunds);

        vm.expectEmit(true, true, true, true);
        emit PostMinted(userWithFunds, 1, TEST_CID, POST_FEE);
        uint256 tokenId = content.mintPost(TEST_CID);
        
        vm.stopPrank();

        assertEq(tokenId, 1);
        // Verifikasi saldo token berkurang
        assertEq(dust.balanceOf(userWithFunds), startBalance - POST_FEE, "Balance should be debited");

        // Verifikasi jumlah post bertambah
        assertEq(identity.getUser(userWithFunds).posts, startPosts + 1, "Post count should increment");
        
        // Verifikasi item konten dibuat
        assertEq(content.getContentItem(tokenId).author, userWithFunds);
    }
}
