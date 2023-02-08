// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The CushyCouches contract is a token following the ERC721 standard
contract CushyCouches is ERC721, Ownable {
  // We will use the Strings library to cast uint256 to string; (help obtain our TokenURI with TokenID that is Uint256)
  using Strings for uint256;
  // Use the Counters library to keep track of the total supply of the token
  using Counters for Counters.Counter;

  // Private variable to keep track of the total supply of the token
  Counters.Counter private supply;

  // Public variables for the URI of the token
  string public uriPrefix = ""; // Used in TokenURI function below
  string public uriSuffix = ".json"; // Metadata files end  in .json
  string public hiddenMetadataUri;
  
  // Public variables for the cost, maximum supply, and maximum mint amount per transaction
  uint256 public maxSupply = 1528;
  uint256 public maxMintAmountPerTx = 10;
  uint256 public currentSupply;
  uint256 public costFlux = 1 + (currentSupply / maxSupply);
  uint256 public cost = (0.0195 * costFlux) ether;
  uint256[] public usedTokenIds; // will be used in version 2.0 to randomize TokenIDs
  bool public revealed = false;
  bool public paused = true;

      // =============================================================================

  constructor() ERC721("Cushy Couch", "CC3") {
    setHiddenMetadataUri("ipfs://QmeMX4QBzfEaTXij4isK9pumVdNTZfA9qiR8Ea9fVvJKnr/HiddenCoushins.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    // Mint amount must be greater than 0 and less than or equal to -> maxMintAmountPerTx
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    // Total supply after minting does not exceed the maxSupply
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    currentSupply = supply.current(); //if 10 tokens have been minted, value will equal 10.
    return supply.current(); //returns the current amount of tokens minted
  }

  // MINT BBG <3
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) { //view mintCompliance modifier above
    require(!paused, "The contract is paused.");
    require(msg.value >= cost * _mintAmount, "Insufficient funds.");

    //or random TokenID, insert for loop here to accomodate for multiple token purchases; or shuffle the array prior to each mint
    /*
    
    
    for (uint256 i = 0; i < _mintAmount; i++) {
      uint256 newTokenId = _generateRandomId();
      _safeMint(msg.sender, newTokenId);
      usedTokenIds.push(newTokenId);
    

    */

    // mint tokens
    _minter(msg.sender, _mintAmount);

    // Update supply and cost. This WILL cost extra gas.
    currentSupply += _mintAmount;
    // Update costFlux
    costFlux = 1 + (currentSupply / maxSupply);
    // Update cost
    cost = (0.0195 * costFlux) ether;


  }

      // ============================================================================= Extraneous functions

/*
function _generateRandomId() internal view returns (uint256) {
    uint256 newTokenId;
    while (true) {
      newTokenId = uint256(keccak256(abi.encodePacked(now, msg.sender, supply.current()))) % (maxSupply + 1);
      if (_tokenIdIsUnique(newTokenId)) {
        break;
      }
    }
    return newTokenId;
  }

  function _tokenIdIsUnique(uint256 _tokenId) internal view returns (bool) {
    for (uint256 i = 0; i < usedTokenIds.length; i++) {
      if (_tokenId == usedTokenIds[i]) {
        return false;
      }
    }
    return true;
  }
}
*/

    // Mint tokens for a specific address
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _minter(_receiver, _mintAmount);
  }

  // Get an array of token IDs owned by a specific address
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    // Get the total number of tokens owned by the address
    uint256 ownerTokenCount = balanceOf(_owner);
    // Create an array to store the token IDs
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    // Initialize the current token ID and owned token index
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    // Go through all the tokens to find the ones owned by the address
    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      // Get the current owner of the token
      address currentTokenOwner = ownerOf(currentTokenId);

      // If the current token is owned by the address, add it to the array
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    // Return the array of token IDs
    return ownedTokenIds;
  }

  // Override the tokenURI function to return the URI for a specific token
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    // Make sure the token exists
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    // If the hidden metadata is not revealed, return the hidden metadata URI
    if (revealed == false) {
      return hiddenMetadataUri;
    }

    // Get the base URI
    string memory currentBaseURI = _baseURI();
    // Return the URI constructed using the base URI, token ID, and URI suffix
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  // Sets the value of the uriPrefix
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  // Withdraw the remaining balance of the contract to the owner
  function withdraw() public onlyOwner {
    // Transfer the remaining contract balance to the owner
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  // Mint tokens for a specific address
  function _minter(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  // Get the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

