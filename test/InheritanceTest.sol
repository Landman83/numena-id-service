// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../src/interfaces/IGateway.sol";

// Test different inheritance orders
contract TestRegistry1 is Ownable {
    IGateway public immutable _gateway;
    
    constructor(address gateway) {
        _gateway = IGateway(gateway);
    }
}

contract TestRegistry2 {
    IGateway public immutable _gateway;
    
    constructor(address gateway) {
        _gateway = IGateway(gateway);
    }
}

contract TestRegistry2Ownable is TestRegistry2, Ownable {
    constructor(address gateway) TestRegistry2(gateway) {}
}

contract InheritanceTest is Test {
    address mockGateway;
    
    function setUp() public {
        mockGateway = address(0x123);
    }

    function testInheritanceOrder() public {
        // Test Ownable first
        TestRegistry1 registry1 = new TestRegistry1(mockGateway);
        assertEq(registry1.owner(), address(this), "Owner not set in Registry1");
        assertEq(address(registry1._gateway()), mockGateway, "Gateway not set in Registry1");
        
        // Test Ownable last
        TestRegistry2Ownable registry2 = new TestRegistry2Ownable(mockGateway);
        assertEq(registry2.owner(), address(this), "Owner not set in Registry2");
        assertEq(address(registry2._gateway()), mockGateway, "Gateway not set in Registry2");
    }
} 