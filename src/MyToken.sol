// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract MyToken is ERC721, Ownable {
    // This is the hardcoded base of your IPFS URI.
    // All tokens return the same metadata JSON IPFS URI.
    // Update this to your actual IPFS CID if needed.
    string private constant TOKEN_DATA_URI = "ipfs://bafkreib4nqvw35hqbtceeaociopj733olrbfd3syr4evjyuda2exzp65si";

    // Price required to mint exactly one token.
    uint256 public constant MINT_PRICE = 0.0005 ether;

    // Revert on incorrect ETH sent for minting.
    error IncorrectPayment();

    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    // Auto-incrementing token id starting from 1.
    uint256 private _nextId = 1;

    /// @dev Public mint that mints to msg.sender with the next token id.
    function mint() external payable returns (uint256 tokenId) {
        if (msg.value != MINT_PRICE) revert IncorrectPayment();
        tokenId = _nextId++;
        _safeMint(msg.sender, tokenId);
    }

    /// @dev Withdraws the entire contract balance to the owner.
    function withdraw() external onlyOwner {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok, "WithdrawFailed");
    }

    /// @dev Overrides the base tokenURI function to return hardcoded token data URI.
     // forge-lint: disable-next-line(mixed-case-function)
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // This check is a good practice to ensure the token actually exists.
        _requireOwned(tokenId);

        // Return hardcoded token data URI.
        return string(abi.encodePacked(TOKEN_DATA_URI));
    }
}
