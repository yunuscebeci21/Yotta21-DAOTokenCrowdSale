// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Listing {
    using SafeMath for uint;

    
    address public immutable treasure; 
    address public immutable withdrawAccount;
    uint public immutable price;
    uint public immutable maxAmountToSale;
    uint public immutable amountToCollect;
    uint public immutable fee;
    uint public immutable saleBeginTime;
    uint public immutable saleEndTime;
    uint public lockupFinishTime;
    bool public status;
    bool public success;
    bool public isWithdraw;

    ERC20 public constant USDC_TOKEN = ERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    ERC20 public immutable listingToken;
    ERC721 public immutable checkToken;
    ERC721 public immutable sbt; 

    mapping(address => uint) public tokenAmount;

    constructor(
        address _sbtAddress,
        address _treasure,
        address _listingTokenAddress, 
        address _tokenToCheck,
        address _withdrawAccount,
        uint _amountToCollect,
        uint _salePrice,
        uint _maxAmountToSale,
        //uint _minAmountToSale,
        uint _saleBeginTime,
        uint _saleEndTime,
        uint _lockupFinishTime
        ) {
        sbt = ERC721(_sbtAddress);
        treasure = _treasure;
        listingToken = ERC20(_listingTokenAddress);
        withdrawAccount = _withdrawAccount;
        price = _salePrice;
        maxAmountToSale = _maxAmountToSale;
        //minAmountToSale = _minAmountToSale;
        amountToCollect = _amountToCollect;
        fee = _amountToCollect.mul(1).div(100);
        saleBeginTime = _saleBeginTime;
        saleEndTime = _saleEndTime;
        lockupFinishTime = _lockupFinishTime;
        checkToken = ERC721(_tokenToCheck);
    }

    function sale(uint _usdcAmount) external {
        require(listingToken.balanceOf(address(this)) != 0, "zero balance");
        require((block.timestamp >= saleBeginTime) && (block.timestamp <= saleEndTime), "not time to sell");
        require(sbt.balanceOf(msg.sender) != 0, "does not have SBT");
        require(tokenAmount[msg.sender] == 0, "sent to address");
        if(address(checkToken) != address(0)) {
            require(checkToken.balanceOf(msg.sender) != 0, "does not have check token");
        }
        USDC_TOKEN.transferFrom(msg.sender, treasure, _usdcAmount.mul(1).div(100));
        uint _remainAmount = _usdcAmount.sub(_usdcAmount.mul(1).div(100));
        uint _amount = _remainAmount.mul(10**18).div(price);
        require(_amount > 0 && _amount <= maxAmountToSale, "amount out of range");
        tokenAmount[msg.sender] = _amount;
        USDC_TOKEN.transferFrom(msg.sender, address(this), _remainAmount);  
    }

    function withdraw() external {
        require(block.timestamp > saleEndTime, "sale is not finish");
        if(!status){ 
           if(USDC_TOKEN.balanceOf(address(this))>=(amountToCollect.mul(80).div(100))){
               success = true; 
           }
           status = true;
        }
        if(success){
            if((msg.sender == withdrawAccount) && !isWithdraw) {
                isWithdraw = true;
                USDC_TOKEN.transfer(treasure, fee);
                USDC_TOKEN.transfer( 
                    withdrawAccount, 
                    USDC_TOKEN.balanceOf(address(this))
                );
              
            }else {
                if(block.timestamp >= lockupFinishTime){
                    listingToken.transfer(msg.sender, tokenAmount[msg.sender]);
                }
                else{
                    revert("lockup is not finish");
                }
            }
        }
        if(!success){
            USDC_TOKEN.transfer(
                msg.sender, 
                tokenAmount[msg.sender].mul(price).div(10**18)
                );
        }
    }
}