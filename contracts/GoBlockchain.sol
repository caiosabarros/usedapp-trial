// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GoBlockchain is ERC1155, Ownable, Pausable, ReentrancyGuard, ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemIds;

    uint256 FEE_PERCENT;
    
    struct SellOffer {
        uint256 itemId;
        address seller;
        uint256 price;
        uint256 amount;
        uint256 createTime;
        uint256 IDtoken;
    }
    struct SoldItem {
        uint256 itemSoldId;
        address seller;
        address buyer;
        uint256 blockId;
        uint256 price;
        uint256 amount;
        uint256 createTime;
        uint256 IDtoken;
    }

    event ItemSold(uint256 tokenId, address indexed seller, uint256 value, uint256 amount, address indexed buyer, uint256 itemSoldId);
    event NewSellOffer(uint256 tokenId, address indexed seller, uint256 value, uint256 amount);
    event CancelSellOffer(uint256 tokenId, address indexed seller, uint256 value, uint256 amount);
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    mapping(uint256 => SellOffer) public activeSellOffers;
    mapping(uint256 => SoldItem) public soldOffers;
    mapping (uint256 => string) private _uris;

    constructor(uint256 feePercent) ERC1155("") {
        FEE_PERCENT = feePercent;
    }

    function balance() public view returns (uint256){
        return address(this).balance;
    }

    function withdrawFunds() public onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 amount, string memory uri) public onlyOwner whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(account, tokenId, amount, "");
        _uris[tokenId] = uri;
        setApprovalForAll(address(this), true);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner whenNotPaused {
        _mintBatch(to, ids, amounts, "");
    }

    function makeSellOffer(uint256 tokenId, uint256 price, uint256 amount) external whenNotPaused nonReentrant tokenOwnerOnly(tokenId) {
        require(price > 0, "Price must be at least 1 wei");
        require(amount > 0, "You can't sell 0 tokens");
        require(this.balanceOf(msg.sender, tokenId) >= amount, "You don't have sufficient balance");

        uint256 itemId = _itemIds.current();
        _itemIds.increment();
        activeSellOffers[itemId] = SellOffer({itemId: itemId, seller : msg.sender, price : price, amount: amount, createTime: block.timestamp, IDtoken: tokenId});
        this.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x");
        emit NewSellOffer(tokenId, msg.sender, price, amount);
    }

    function buyToken(uint256 item) public payable whenNotPaused nonReentrant returns (SellOffer memory) {
        SellOffer memory offer = activeSellOffers[item];
        require(msg.value >= offer.price, "You can't send less than the offer price!");
        emit MoneyReceived(msg.sender, msg.value);
        uint256 fee_tax = (msg.value / 100) * FEE_PERCENT;
        uint256 seller_ammount = msg.value - fee_tax;
        this.safeTransferFrom(address(this), address(msg.sender), offer.IDtoken, offer.amount, "0x");
        payable(offer.seller).transfer(seller_ammount);
        emit MoneySent(address(offer.seller), seller_ammount);
        uint256 itemSoldId = _itemsSold.current();
        _itemsSold.increment();
        soldOffers[itemSoldId] = SoldItem({
            itemSoldId: itemSoldId,
            seller: offer.seller,
            buyer: msg.sender,
            blockId: block.number,
            price: offer.price,
            amount: offer.amount,
            createTime: block.timestamp,
            IDtoken: offer.IDtoken
        });
        emit ItemSold(offer.IDtoken, offer.seller, offer.price, offer.amount, msg.sender, itemSoldId);
        delete activeSellOffers[item];
        return offer;
    }
    
    function fetchMarketItems() public view returns (SellOffer[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        SellOffer[] memory items = new SellOffer[](unsoldItemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            if (activeSellOffers[i].seller != address(0)) {
                uint256 currentId = activeSellOffers[i].itemId;
                SellOffer storage currentItem = activeSellOffers[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function cancelSellOffer(uint256 tokenId) public whenNotPaused nonReentrant {
        SellOffer memory offer = activeSellOffers[tokenId];
        require(address(offer.seller) == address(msg.sender), "You aren't the token seller");
        this.safeTransferFrom(address(this), address(msg.sender), offer.IDtoken, offer.amount, "0x");
        emit CancelSellOffer(offer.IDtoken, offer.seller, offer.price, offer.amount);
        delete activeSellOffers[tokenId];
    }

    function token_uri(uint256 tokenId) public view returns (string memory) {
        return(_uris[tokenId]);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    modifier tokenOwnerOnly(uint256 tokenId) {
        require(this.balanceOf(msg.sender, tokenId) != 0, "You don't have any token");
        _;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
