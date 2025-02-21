// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../test/LayoutTest.sol";

contract DeployLayoutTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy test contract
        LayoutTest test = new LayoutTest();
        
        // Run the test
        test.setUp();
        test.testStorageLayout();

        vm.stopBroadcast();
    }
} 