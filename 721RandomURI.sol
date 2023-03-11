// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  bytes32 public baseURIHash;
  string public baseExtension = ".json";
  string public notRevealedUri;
  
  uint256 public maxSupply = 1528;
  uint256 public maxMintAmount = 20;
  uint256 public cost = 19500000000000000; // 0.0195 ether in wei

  bool public paused = true;
  bool public revealed = false;

  constructor(
    string memory _name, 
    string memory _symbol, 
    bytes32 _initBaseURIHash,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURIHash(_initBaseURIHash);
    setNotRevealedURI(_initNotRevealedUri);
  }

  function _baseURIHash() internal view virtual returns (bytes32) {
    return baseURIHash;
  }

// Mapping to keep track of used token numbers
mapping (uint256 => bool) private usedTokenNumbers;

// Function to generate a random number between 1 and maxSupply that has not been used before
function generateRandomTokenNumber() private returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % maxSupply + 1;
    while (usedTokenNumbers[randomNumber]) {
        randomNumber = (randomNumber + 1) % maxSupply + 1;
    }
    usedTokenNumbers[randomNumber] = true;
    return randomNumber;
}

// Function to mint NFTs using a random token number
function mintRandom(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "The contract is currently paused");
    require(_mintAmount > 0, "Invalid mint amount");
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        require(msg.value >= cost * maxSupply / (supply + 1) * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        uint256 tokenId = generateRandomTokenNumber();
        _safeMint(msg.sender, tokenId);
        supply += 1;
    }
}


  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(revealed == false) {
        return notRevealedUri;
    }
    bytes32 currentBaseURIHash = _baseURIHash();
    return currentBaseURIHash.length > 0
        ? string(abi.encodePacked(bytes32ToString(currentBaseURIHash), tokenId.toString(), baseExtension))
        : "";
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    bytes memory bytesArray = new bytes(64);
    for (uint256 i = 0; i < 32; i++) {
      uint256 value = uint256(_bytes32[i]);
      bytesArray[i * 2] = bytes1(uint8(value / 16 + 48));
      bytesArray[i * 2 + 1] = bytes1(uint8(value % 16 + 48));
    }
    return string(bytesArray);
  }

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

  function setBaseURIHash(bytes32 _newBaseURIHash) public onlyOwner {
    baseURIHash = _newBaseURIHash;
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

  receive() external payable {}
}
