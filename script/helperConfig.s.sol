//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* 1. Deploy mocks when we are on local chain
2. Keep track of forked chain id
3. If we are on a forked chain, use the mock address
4. If we are on a local chain, deploy mocks and use the mock address
5. If we are on a testnet, use the real address
6. If we are on a mainnet, use the real address
 */

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor(){
        if (block.chainid == 11155111) { // Sepolia
            activeNetworkConfig = getSepoliaETHConfig();
        } else if (block.chainid == 31337) { // Anvil
            activeNetworkConfig = getAnvilETHConfig();
        } else {
            revert("Unsupported network");
        }
    }

    struct NetworkConfig {
        address priceFeed; // Address of the price feed contract
    }
    function getSepoliaETHConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD price feed address
        });
    }
    function getAnvilETHConfig() internal returns (NetworkConfig memory) {
        if(activeNetworkConfig.priceFeed != address(0)) {  // If we have already set the config
            return activeNetworkConfig; // Return the existing config if already set
        }
        // Here we will deploy a mock price feed contract
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // 2000 USD in 8 decimals
        vm.stopBroadcast();

        return NetworkConfig({
            priceFeed: address(mockPriceFeed) // Address of the mock price feed contract
        });
    }
}