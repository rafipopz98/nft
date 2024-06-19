// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    // how many numbers of nft tokens are dold, are present;
    // no.of tokens, nft will have id and we inrement using Counter while adding
    Counters.Counter private _tokenIds;
    // when token is sold we will incremet
    Counters.Counter private tokenSold;

    address payable owner;

    // every nft will have unique id
    // and each nft will be stored in marketItem
    // just adding the market id to the struct

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    constructor() ERC721("NFT MetaverseToken", "MYNFT") {
        owner == payable(msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You dont have access to this, Only Owner can access this"
        );
        _;
    }

    // for listing  a token the user has to pay me then only he can sell his nft in my application
    // initial amount will be 0.0025, if i want to increase or descrease i can use this;
    // create a modifier so that only owner can have access to this particular function

    uint256 listingPrice = 0.0025 ether;

    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    // fn to get listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //  creating nft token
    function createNFTToken(
        string memory tokenURI,
        uint256 price
    ) public returns (uint256) {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    // creating martket item

    function createMarketItem(uint256 _tokenId, uint256 _price) private {
        require(_price > 0, "Price must be greater than 0");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price, 0.0025 ether"
        );

        idMarketItem[_tokenId] = MarketItem(
            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            false
        );

        // we have successfull created a nft and added to market
        // now let transfer the nft from seller  to the market i.e this contract
        _transfer(msg.sender, address(this), _tokenId);

        // emit the event
        emit MarketItemCreated(
            _tokenId,
            msg.sender,
            address(this),
            _price,
            false
        );
    }

    // fn to resell the nft token
    function resellNFT(uint256 _tokenId, uint256 _price) public {
        require(
            idMarketItem[_tokenId].owner == msg.sender,
            "Only onwer can resll the token, you canot perform this action"
        );
        require(
            _price == listingPrice,
            "The price must be equal to listing price"
        );

        idMarketItem[_tokenId].sold = false;
        idMarketItem[_tokenId].price = _price;
        idMarketItem[_tokenId].seller = payable(msg.sender);
        idMarketItem[_tokenId].owner = payable(address(this));

        // once some one resells it then itemsold or the no. of token sold must decreemtted
        tokenSold.decrement();

        // transfer it

        _transfer(msg.sender, address(this), _tokenId);
    }

    function createMarketSale(uint256 _tokenId) public payable {
        uint256 price = idMarketItem[_tokenId].price;
        require(
            msg.value == price,
            "The enter the asking price to complete the purchase"
        );

        idMarketItem[_tokenId].owner = payable(msg.sender);
        idMarketItem[_tokenId].sold = true;
        idMarketItem[_tokenId].owner = payable(address(0));

        tokenSold.increment();

        _transfer(address(this), msg.sender, _tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[_tokenId].seller).transfer(msg.value);
    }

    // fn to get all unsold token

    function getAllUnsoldTokens() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldTokenCount = _tokenIds.current() - tokenSold.current();

        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unSoldTokenCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // purchased token

    function fetchMyNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // single user tokens

    function fetchItemListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // get token detail

    function getSingletoken(
        uint256 _tokenId
    ) public view returns (MarketItem memory) {
        bool exist = _exists(_tokenId);
        require(exist, "The token doesnot exist!");
        MarketItem memory item = idMarketItem[_tokenId];
        return item;
    }
}
