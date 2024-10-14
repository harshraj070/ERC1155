// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MyToken is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply,PaymentSplitter {

    uint256 public publicprice = 0.02 ether;
    uint256 public allowListPrice = 0.01 ether;
    uint256 public MaxSupply = 2;
    uint256 public maxPerWallet = 3;

    bool public publicListMintopen = false;
    bool public allowListMintopen = false;

    mapping(address => bool)public allowList;
    mapping(address => uint256) public purchasesPerWallet;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares
    )
    {
        ERC1155("ipfs://Qmaa6TuP2s9pSKczHF4rwWhTKUdygrrDs8RmYYqCjP3Hye/");
        PaymentSplitter(_payees, _shares);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setAllowList(address[] calldata addresses)external onlyOwner{
        for(uint i=0;i<addresses.length;i++){
            allowList[addresses[i]] = true;
        }
    }
    function editWindows(
        bool _publicListopen,
        bool _allowListmintopen
    ) external onlyOwner{
        publicListMintopen = _publicListopen;
        allowListMintopen = _allowListmintopen;
    }

    function publicMint(uint256 id, uint256 amount)
        public 
        payable
    {
        require(publicListMintopen,"Not allowed to mint publically");
        require(msg.value == publicprice * amount,"Not enough value");
        mint(id, amount);
        
    }
    function allowListmint(uint id, uint amount)public payable{
        require(allowList[msg.sender],"You are not on the allowList");
        require(allowListMintopen,"Not allowed to mint the allowLisy");
        require(msg.value == allowListPrice * amount, "Not enough value");
        mint(id, amount);
    }

    function uri(uint256 _id)public view virtual override returns(string memory){
        require(exists(_id),"URI non existent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    function mint(uint256 id,uint256 amount) internal{
        require(purchasesPerWallet[msg.sender]<= maxPerWallet,"Maximum purchase limit reached");
        require(totalSupply(id) + amount <= MaxSupply, "Supply limit reached");
        _mint(msg.sender, id, amount, "");   
        require(id < 2,"Sorry, you are trying to mint the wrong NFT"); 
        purchasesPerWallet[msg.sender] += amount;   
    }

    function withdraw(address _addr) external onlyOwner{
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
