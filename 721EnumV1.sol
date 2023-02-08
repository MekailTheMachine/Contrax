// SPDX-License-Identifier: MIT

// Specify the required version of Solidity compiler
pragma solidity >=0.7.0 <0.9.0;

// Import two libraries: ERC721Enumerable and Ownable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract NFT inherits from the ERC721Enumerable and Ownable contracts
contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Variables
  string baseURI; // base URI that will be used to generate the full token URI
  string public baseExtension = ".json"; // file extension that will be used to generate the full token URI

  uint256 public maxSupply = 1528; // maximum number of tokens that can be minted
  uint256 public maxMintAmountPerTx = 20; // maximum number of tokens that can be minted in one transaction
  uint256 public currentSupply; // the current number of tokens in circulation
  uint256 public costFlux = 1 + (currentSupply/ maxSupply); // the rate at which the cost of minting changes
  uint256 public cost = (1.95 * costFlux) * 10**16; // the cost of minting tokens
  uint256 public maxMintAmount;

  // uint256[] public usedTokenIds; // an array that will be used in version 2.0 to randomize TokenIDs

  bool public paused = true;
  bool public revealed = false; 
  string public notRevealedUri; // the URI to be returned if the metadata of the tokens is not revealed

  // Contract constructor
  constructor(
    string memory _name, 
    string memory _symbol, 
    string memory _initBaseURI, // the initial base URI
    string memory _initNotRevealedUri // the initial URI to be returned if the metadata of the tokens is not revealed
  ) ERC721(_name, _symbol) {
    // Initialize the base URI
    setBaseURI(_initBaseURI);
    // Initialize the URI to be returned if the metadata of the tokens is not revealed
    setNotRevealedURI(_initNotRevealedUri);
  }

  // Internal function that returns the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // ========== Mint function ==========================================================================================
  function mint(uint256 _mintAmount) public payable {
    // Check if the contract is paused and the mint amount is more than zero
    require(!paused, "The contract is currently paused");
    require(_mintAmount > 0, "Invalid mint amount");
    require(_mintAmount <= maxMintAmountPerTx, "Exceeded max mint amount per transaction");

    // Check if the sender of the transaction is not the contract owner
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Insufficient funds");
    }
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "Max supply exceeded");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      // Mint the tokens and add them to the sender's balance
      _safeMint(msg.sender, supply + i);
    }

    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      // Check if the value of the message sent by the sender is greater than or equal to the cost of minting
      require(msg.value >= cost * _mintAmount);
    }

    // Loop to mint the specified number of tokens
    for (uint256 i = 1; i <= _mintAmount; i++) {
      // Mint a token and assign it to the sender of the message
      _safeMint(msg.sender, supply + i);
    }

    // Update the current supply and costFlux variables
    currentSupply += _mintAmount;
    costFlux = 1 + (currentSupply / maxSupply);
    cost = 1.95 * 10**16 * costFlux;
    
  }

// ============================= OTHER PUBLIC FUNCTIONS ===============================================================
  // Function to get the token IDs of all tokens owned by a particular address
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    // Get the total number of tokens owned by the address
    uint256 ownerTokenCount = balanceOf(_owner);
    
    // Create an array to store the token IDs of the tokens owned by the address
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    
    // Loop through each of the tokens owned by the address and get its token ID
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    
    // Return the array of token IDs
    return tokenIds;
  }

  // Function to get the token URI for a specific token ID
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    // Check if the token ID exists
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    // If the tokens have not been revealed, return the notRevealedUri string
    if(revealed == false) {
        return notRevealedUri;
    }

    // Get the current base URI
    string memory currentBaseURI = _baseURI();
    
    // If the length of the current base URI is greater than 0, return the concatenated string of the base URI, the token ID, and the base extension
    // Otherwise, return an empty string
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

// ========================= FUNCTIONS TO BE CALLED BY THE CONTRACT OWNER ONLY =================================================

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
