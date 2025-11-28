// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Identity} from "./Identity.sol";
import {DustToken} from "./DustToken.sol";
import {SharedTypes} from "./SharedTypes.sol";

/// @notice A contract for content that is also a soul-bound ERC721 token.
contract Content is ERC721, Ownable {
    Identity public identity;
    DustToken public dust;
    uint256 public constant POST_FEE = 10e18; // 10 DUST

    // --- SBT State ---
    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenCIDs;
    uint256 private _nextTokenId = 1;

    // --- Content State ---
    mapping(uint256 => SharedTypes.ContentItem) public contentItems;

    event PostMinted(address indexed user, uint256 indexed tokenId, string cid, uint256 fee);

    constructor(
        Identity identity_,
        DustToken dust_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        identity = identity_;
        dust = dust_;
        _baseTokenURI = baseURI_;
    }

    /// @notice Mints a new content post as an SBT, charging a DUST fee.
    /// @param cid The IPFS Content Identifier for the post's metadata.
    /// @return tokenId The ID of the newly created content post and token.
    function mintPost(string calldata cid) external returns (uint256 tokenId) {
        // 1. Charge fee
        dust.burn(msg.sender, POST_FEE);

        // 2. Mint the Soul-Bound Token internally
        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _tokenCIDs[tokenId] = cid;

        // 3. Create the on-chain content item
        contentItems[tokenId] = SharedTypes.ContentItem({
            id: tokenId,
            author: msg.sender
        });

        // 4. Update user's general post count
        identity.addPost(msg.sender);

        emit PostMinted(msg.sender, tokenId, cid, POST_FEE);
    }
    
    /// @notice Returns the full URI for a given token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseTokenURI, _tokenCIDs[tokenId]));
    }

    function getContentItem(uint256 tokenId) external view returns (SharedTypes.ContentItem memory) {
        return contentItems[tokenId];
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
