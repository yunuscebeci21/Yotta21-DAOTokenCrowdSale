// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SBT is ERC721, Ownable {
  using SafeMath for uint;
  using Counters for Counters.Counter;
  Counters.Counter private tokenIds;

  struct Checkpoint {
    uint32 fromBlock;
    uint votes;
  }
  
  uint public totalSupply;
  uint public supply;
  uint public price;
  uint public refMemberAmount;
  uint public yotta21Amount; 
  address public timelock;
  address public treasure;
  string private contractCID =
    "QmcUGJ838Y5MoyasPfC3HVMYJP4obgyxMchkP7p4aWnhTz";
  ERC20 public token;

  mapping(address => address) public delegates;
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
  mapping(address => uint32) public numCheckpoints;

  constructor(address _token) ERC721("SBT", "SBT") {
    price = 0;
    require(_token != address(0), "Zero Address");
    token = ERC20(_token);
    supply = 200000000;
  }

  /// @notice Delegate votes from `msg.sender` to `delegatee`
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  function setTreasure(address _treasure) external onlyOwner {
    require(_treasure != address(0), "Zero Address");
    treasure = _treasure; 
  }

  function setCostToken(address _costToken) external onlyOwner {
    require(_costToken != address(0), "Zero Address");
    token = ERC20(_costToken); 
  }

  /*function setSupply(uint _newSupply) external onlyOwner {
    require(_newSupply > supply, "New supply is smaller than supply");
    supply = _newSupply; 
  }*/

  function saleToReferral(address _refAddress) external {
    require(balanceOf(msg.sender) == 0, "Recipient has SBT"); 
    require(balanceOf(_refAddress) != 0, "Referance has SBT"); 
    totalSupply = totalSupply + 1;
    require(totalSupply <= supply, "SBT supply finished");
    _mintSBT(msg.sender);
    if(price!=0){
      bool success = token.transferFrom(msg.sender, treasure, yotta21Amount);
      require(success, "Transfer failed");
      bool success1 = token.transferFrom(msg.sender, _refAddress, refMemberAmount);
      require(success1, "Transfer failed");
    }
  }

  function saleToDefault() external {
    require(balanceOf(msg.sender) == 0, "Recipient has SBT");
    totalSupply = totalSupply + 1;
    require(totalSupply <= supply, "SBT supply finished");
    _mintSBT(msg.sender);
    if(price!=0){
      bool success = token.transferFrom(msg.sender, treasure, price);
      require(success, "Transfer failed");
    }
  }

  function setTimelock(address _timelock) public onlyOwner {
    require(_timelock != address(0), "Zero Address");
    timelock = _timelock;
    transferOwnership(timelock);
  }

  function setAmounts(uint _newPrice, uint _refMemberAmount, uint _yotta21Amount) public onlyOwner {
    price = _newPrice;
    refMemberAmount = _refMemberAmount;
    yotta21Amount = _yotta21Amount;
  }

  /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked("ipfs://", contractCID));
  }
  
  function _mintSBT(address _account) internal {
    tokenIds.increment();
    uint newItemId = tokenIds.current();
    _safeMint(_account, newItemId);
  }
   
  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
  ) public virtual override(ERC721) {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
      _beforeTokenTransfer(
         from,
         to,
         tokenId
      );
      _safeTransfer(from, to, tokenId, data);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721) {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: caller is not token owner nor approved"
    );
    _beforeTokenTransfer(
         from,
         to,
         tokenId
    );
    _transfer(from, to, tokenId);
  }

  function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            return;
        }
        require(from == to, "not same address");
    }

    function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint delegatorBalance = balanceOf(delegator);
    delegates[delegator] = delegatee;
    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepNew);
      }
      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      "Comp::_writeCheckpoint: block number exceeds 32 bits"
    );
    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }
  }

  function safe32(uint n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }
 
 
}


