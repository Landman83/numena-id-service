// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../test/InterfaceTest.sol";

contract DeployInterfaceTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy and test in one step
        InterfaceTest test = new InterfaceTest();
        test.testGatewayInterface();

        vm.stopBroadcast();
    }
} 