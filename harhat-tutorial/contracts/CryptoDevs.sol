//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {

    // the resulting URI of each token will be a concatenation of _baseTokenURI
    string _baseTokenURI;

    // _price is the price of one Crypto Dev NFT
    uint256 public _price = 0.01 ether;

    // _paused is used to pause the contract in case of an emergency
    bool public _paused;

    // max number of CryptoDevs
    uint256 public maxTokenIds = 20;

    // total number of tokenIds minted
    uint256 public tokenIds;

    //Whitelist contract instance;
    IWhitelist whitelist;

    // boolean to keep track of whether presale started or not
    bool public presaleStarted;

    // timestamp for when presale would end
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    /**
    ERC721 contstructor takes in a 'name' and a 'symbol' to the token collection.
    name in our case is 'Crypto Devs' and symbol is 'CD'.
    Constructor for Crpyto Devs takes in the baseURI to set _baseTokenURI for the collection
    It also initializes an instance of whitelist interface.
     */

    constructor (string memory baseURI, address whitelistContract) ERC721("CryptoDevs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    /**
    startPresale starts a presale for the whitelisted addresses
     */

     function startPresale() public onlyOwner {
        presaleStarted = true;
        // set presale ended time as a current timestamp + 5min;
        // solidity has cool syntax for timestamps (seconds, minutes, hours, days, years)
        presaleEnded = block.timestamp + 5 minutes;
     }

     
     /**
     presaleMint allows a user to mint one NFT per transaction during the presale;
      */

      function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not currently running");
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;

        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // if the address being minted to is not a contract, it works the same way as _mint
        _safeMint(msg.sender, tokenIds);
      }

      /**
      mint allows a user to mint 1 NFT per transaction after the presale has ended
       */

       function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >= presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceeded max Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
       }

       //_baseURI overrides the Openzeppelin's ERC721 implementation which by default returned an empty string for the baseURI

       function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
       }

       /**
       setPaused makes the contract paused or unpaused
        */

        function setPaused(bool val) public onlyOwner {
            _paused = val;
        
        }

        /**
        withdraw sends all the ether in the cotnract to the owner of the contract
         */

         function withdraw() public onlyOwner {
            address _owner = owner();
            uint256 amount = address(this).balance;
            (bool sent, ) = _owner.call{value: amount}("");
            require(sent, "Failed to send Ether");
         }

    /**
    function to receive ether. msg.data must be empty
     */

     receive() external payable {}

     //Fallback function is called when msg.data is not empty

     fallback() external payable {}




}