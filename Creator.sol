// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Listing } from "./Listing.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Creator is Ownable {
    using SafeMath for uint;

    struct ProjectInformation {
        address owner;
        address listingContract;
        string uri;
    }

    address public immutable treasure;
    uint public constant MIN_AMOUNT_TO_COLLECT = 100*10**21;
    uint public listingPriceForPercentage;

    ERC20 public immutable usdcToken; 
    ERC721 public immutable sbt;

    ProjectInformation[] public projects;

    constructor(address _treasure, address _sbt, address _usdcToken) {
        treasure = _treasure; 
        sbt = ERC721(_sbt);      
        usdcToken = ERC20(_usdcToken); 
    }

    function setListingPrice(uint _listingPriceForPercentage) external onlyOwner {
        require(_listingPriceForPercentage>0 && _listingPriceForPercentage<=1);
        listingPriceForPercentage = _listingPriceForPercentage;
    } 

    function create(
         string memory _projectInformationUri,
         address _listingTokenAddress, 
         address _checkTokenAddress, 
         address _withdrawAccount,
         uint _listingTokenAmount,
         uint _usdcCollectAmount,
         uint _maxAmountToSale,
         uint _saleBeginTime,
         uint _saleEndTime,
         uint _lockupFinishTime
    )
        external
        returns (address)
    {
        require(sbt.balanceOf(msg.sender) != 0, "does not have SBT");
        require(_usdcCollectAmount>=MIN_AMOUNT_TO_COLLECT, "not min amount to collect");
        //require((_minAmountToSale > 0) && (_maxAmountToSale > 0) && (_minAmountToSale < _maxAmountToSale), "Amounts are wrong");
        require((_saleBeginTime != _saleEndTime) && (_saleEndTime > block.timestamp), "times are false");
        require(_lockupFinishTime >= _saleEndTime, "lockup time is false");
     
        uint _salePrice = _usdcCollectAmount.mul(10**18).div(_listingTokenAmount);
        uint _listingPrice = _usdcCollectAmount.mul(listingPriceForPercentage).div(10**20);

        Listing tokenToList = new Listing(
            address(sbt),
            treasure,
           _listingTokenAddress,
           _checkTokenAddress, 
           _withdrawAccount,
           _usdcCollectAmount,
           _salePrice,
           _maxAmountToSale,
           _saleBeginTime,
           _saleEndTime,
           _lockupFinishTime
        );

        ProjectInformation memory project;
        project.owner = msg.sender;
        project.listingContract = address(tokenToList);
        project.uri = _projectInformationUri;

        projects.push(project);


        if(listingPriceForPercentage != 0) {
           usdcToken.transferFrom(
               msg.sender, 
               treasure, 
               _listingPrice
               );
        }

        ERC20 token = ERC20(_listingTokenAddress);
        token.transferFrom(msg.sender, address(tokenToList), _listingTokenAmount);

        return address(tokenToList);
    }

    function viewProjects() external view returns(ProjectInformation[] memory) {
        return projects;
    }
}
