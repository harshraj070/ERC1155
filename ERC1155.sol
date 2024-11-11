// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MyToken is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply, PaymentSplitter {

    uint256 public publicMintPrice = 0.02 ether;
    uint256 public allowListMintPrice = 0.01 ether;
    uint256 public maxTokenSupply = 2;
    uint256 public maxTokensPerWallet = 3;

    bool public isPublicMintOpen = false;
    bool public isAllowListMintOpen = false;

    mapping(address => bool) public allowList;
    mapping(address => uint256) public walletMintCount;

    constructor(
        address[] memory payees,
        uint256[] memory shares
    ) ERC1155("ipfs://Qmaa6TuP2s9pSKczHF4rwWhTKUdygrrDs8RmYYqCjP3Hye/") 
      PaymentSplitter(payees, shares) {}

    function setURI(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function updateAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    function setMintWindows(
        bool publicMintOpen,
        bool allowListMintOpen
    ) external onlyOwner {
        isPublicMintOpen = publicMintOpen;
        isAllowListMintOpen = allowListMintOpen;
    }

    function mintPublic(uint256 tokenId, uint256 amount) external payable {
        require(isPublicMintOpen, "Public minting is not open");
        require(msg.value == publicMintPrice * amount, "Incorrect payment amount");
        _mintTokens(tokenId, amount);
    }

    function mintAllowList(uint256 tokenId, uint256 amount) external payable {
        require(allowList[msg.sender], "Address not on allow list");
        require(isAllowListMintOpen, "Allow list minting is not open");
        require(msg.value == allowListMintPrice * amount, "Incorrect payment amount");
        _mintTokens(tokenId, amount);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId), ".json"));
    }

    function _mintTokens(uint256 tokenId, uint256 amount) internal {
        require(walletMintCount[msg.sender] + amount <= maxTokensPerWallet, 
            "Exceeded max tokens per wallet");
        require(totalSupply(tokenId) + amount <= maxTokenSupply, 
            "Exceeded max supply for token");
        require(tokenId < 2, "Invalid token ID");

        _mint(msg.sender, tokenId, amount, "");
        walletMintCount[msg.sender] += amount;
    }

    function withdrawFunds(address recipient) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(recipient).transfer(contractBalance);
    }

    function mintBatchTokens(
        address to, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts, 
        bytes memory data
    ) external onlyOwner {
        _mintBatch(to, tokenIds, amounts, data);
    }

    function burnTokens(address account, uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(account, tokenId, amount);
    }

    function giftTokens(
        address[] calldata recipients, 
        uint256 tokenId, 
        uint256 amount
    ) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId, amount, "");
        }
    }

    function _update(
        address from, 
        address to, 
        uint256[] memory tokenIds, 
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, tokenIds, values);
    }
}
