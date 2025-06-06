//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/Fund_Me.sol";
import {HelperConfig} from "../script/helperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns(FundMe) {

        //Before startBroadcast -> Only local transactions are sent to the blockchain
        HelperConfig helperConfig = new HelperConfig();
        //After startBroadcast -> Real transactions are sent to the blockchain
        address priceFeed = helperConfig.activeNetworkConfig();
        
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}