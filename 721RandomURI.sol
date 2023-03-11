// SPDX-License-Identifier: MIT

// Specify the required version of Solidity compiler
pragma solidity >=0.7.0 <0.9.0;

// Import two libraries: ERC721Enumerable and Ownable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract inherits from the ERC721Enumerable and Ownable contracts
contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Variables
  string baseURI; // base URI that will be used to generate the full token URI
  string public baseExtension = ".json"; // file extension that will be used to generate the full token URI
  string public notRevealedUri; // the URI to be returned if the metadata of the tokens is not revealed
  
  uint256 public maxSupply = 1528;
  uint256 public maxMintAmount = 20;
  uint256 public currentSupply = 0;
  uint256 public costFlux = 1 + (currentSupply/ maxSupply);
  uint256 public cost = 0.0195 ether;

  bool public paused = true;
  bool public revealed = false;

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

    // Mapping to keep track of used token numbers
  mapping (uint256 => bool) private usedTokenNumbers;

    // Function to generate a random number between 1 and maxSupply that has not been used before
  function generateRandomTokenNumber() private returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, baseURI))) % maxSupply + 1;
    while (usedTokenNumbers[randomNumber]) {
        randomNumber = (randomNumber + 1) % maxSupply + 1;
    }
    usedTokenNumbers[randomNumber] = true;
    return randomNumber;
  }

  // ======================== MINT FUNCTION ==================================================
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "The contract is currently paused");
    require(_mintAmount > 0, "Invalid mint amount");
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * costFlux * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        uint256 tokenId = generateRandomTokenNumber();
        _safeMint(msg.sender, tokenId);
        supply += 1;
    }

    costFlux = 1 + (currentSupply / maxSupply);
      // mint tokens, and update the cost flux
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

  // TokenURI - TokenID pairing
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