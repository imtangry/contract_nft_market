// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract NFTMarket is ERC721URIStorage {
    address public owner;

    uint256 tokenId = 0;

    uint256 total = 0;

    uint256 itemSold = 0;

    uint256 listingPrice = 0.001 ether;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only contract owner can do this");
        _;
    }

    event idMarketItemCreated(
        uint256 indexed tokerId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // CREATE NFT TOKEN
    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        uint256 newId = tokenId;
        tokenId = tokenId + 1;
        total = total + 1;
        _safeMint(msg.sender, newId);
        _setTokenURI(newId, tokenURI);
        // 创建了一个NFT 且发布到了市场
        createMarketItem(newId, price);
        return newId;
    }

    function createMarketItem(uint256 id, uint256 price) private {
        require(price > 0, "price can not be zero");
        require(msg.value == listingPrice, "price must equal to listtingPrice");
        idMarketItem[id] = MarketItem(
            id,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        // 将卖家的nft移交给当前合约？
        _transfer(msg.sender, address(this), id);

        emit idMarketItemCreated(id, msg.sender, address(this), price, false);
    }

    // 重新上架NFT 创建卖单 售出-1
    function resellToken(uint256 id, uint256 price) public payable {
        MarketItem storage item = idMarketItem[id];
        require(item.owner == msg.sender, "only item owner can change price");
        require(
            msg.value == listingPrice,
            "price must be equal to listingPrice"
        );

        item.price = price;
        item.owner = payable(address(this));
        item.seller = payable(msg.sender);
        item.sold = false;

        itemSold = itemSold - 1;

        // 将NFT所有权交给合约
        _transfer(msg.sender, address(this), tokenId);
    }

    // 创建买单 售出+1
    function createMarketSale(uint256 id) public payable {
        // 这个会消耗更多gas么
        MarketItem storage item = idMarketItem[id];
        uint256 price = item.price;
        require(price == msg.value, "please submit asking price");
        item.owner = payable(msg.sender);
        item.sold = true;

        itemSold = itemSold + 1;
        // 合约所有者从市场转移到买家
        _transfer(address(this), msg.sender, id);

        // 合约（NFT市场）所有者收取挂牌价格
        payable(owner).transfer(listingPrice);
        // 剩余交付给NFT卖家
        payable(item.seller).transfer(msg.value);
    }

    // 获取未售出的NFT
    function getMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = tokenId;
        uint256 unSold = total - itemSold;
        uint256 index = 0;

        MarketItem[] memory items = new MarketItem[](unSold);

        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i].owner == address(this)) {
                uint256 currentId = i;
                MarketItem storage item = idMarketItem[currentId];
                items[index] = item;
                index += 1;
            }
        }
        return items;
    }

    // 我的NFT
    function getMyNft() public view returns (MarketItem[] memory) {
        uint256 totalCount = tokenId;
        uint256 itemCount = 0;
        uint256 index = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i].owner == msg.sender) {
                uint256 currentId = i;
                MarketItem storage item = idMarketItem[currentId];
                items[index] = item;
                index += 1;
            }
        }
        return items;
    }

    //获取我出售中的NFT
    function getItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = tokenId;
        uint256 itemCount = 0;
        uint256 index = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i].seller == msg.sender) {
                uint256 currentId = i;
                MarketItem storage item = idMarketItem[currentId];
                items[index] = item;
                index += 1;
            }
        }
        return items;
    }

    constructor() ERC721("Daisy NFT Market", "daisy_nft_market_01") {
        owner = payable(msg.sender);
    }
}
