// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UsdcToken is ERC20, Ownable {
    using SafeMath for uint;

    mapping(address => bool) public isMint;
    
    ERC721 immutable sbt;

    constructor(address _sbtAddress) ERC20("UsdcToken", "USDC") {
        sbt = ERC721(_sbtAddress);
        _mint(address(this), 100*10**27);
        _transfer(address(this), owner(), 100*10**24);
    }

     function mintUsdcToken() external {
        require(sbt.balanceOf(msg.sender) != 0, "no sbt token");
        require(!isMint[msg.sender], "mint");
        isMint[msg.sender] = true;
        _transfer(address(this), msg.sender, 10*10**21);
    }

    function mintUsdcTokenToOwner(uint _amount) external onlyOwner {
        _transfer(address(this), owner(), _amount);
    }

}
