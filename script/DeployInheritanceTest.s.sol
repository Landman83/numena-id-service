// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../test/InheritanceTest.sol";

contract DeployInheritanceTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy test contract
        InheritanceTest test = new InheritanceTest();
        
        // Run the test
        test.setUp();
        test.testInheritanceOrder();

        vm.stopBroadcast();
    }
} 