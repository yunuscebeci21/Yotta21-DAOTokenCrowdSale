// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract Treasure is KeeperCompatibleInterface {

    address public addressToTransfered;
    uint public year = 86400 * 365; // 1 gün * 365 
    uint public lastTimeStamp;

    ERC20 public immutable usdcToken;

    constructor(address _usdcToken) {
        lastTimeStamp = block.timestamp;
        usdcToken = ERC20(_usdcToken); 
    }

    modifier checkAddressZero() {
        require(addressToTransfered != address(0), "zero address");
        _;
    }

    function setAddressToTransfered(address _addressToTransfered) external {
        require(_addressToTransfered != address(0), "Zero Address");
        addressToTransfered = _addressToTransfered; 
    }

    function performUpkeep(bytes calldata performData) external override checkAddressZero {
        require((block.timestamp - lastTimeStamp) >= year, "not epoch");
        lastTimeStamp = block.timestamp;
        transfer();
        performData;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        checkAddressZero
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) >= year;
        performData = checkData;
    }

    function transfer() internal checkAddressZero {
        usdcToken.transfer(addressToTransfered, usdcToken.balanceOf(address(this)));
        //event
    }
}