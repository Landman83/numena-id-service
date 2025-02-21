// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../test/StateTest.sol";

contract DeployStateTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy test contract
        StateTest test = new StateTest();
        
        // Run the test
        test.setUp();
        test.testStateInitialization();

        vm.stopBroadcast();
    }
} 