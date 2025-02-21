// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../src/interfaces/IGateway.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "@onchain-id/solidity/contracts/gateway/Gateway.sol";

// 1. Minimal Registry - just stores addresses
contract MinimalRegistry is Ownable {
    address public immutable gateway;
    address public immutable factory;
    address public immutable authority;
    
    constructor(address g, address f, address a) {
        gateway = g;
        factory = f;
        authority = a;
    }
}

// 2. Gateway Registry - interacts with Gateway
contract GatewayRegistry is Ownable {
    IGateway public immutable gateway;
    
    constructor(address g) {
        gateway = IGateway(g);
        // Try to call a Gateway function
        require(address(gateway.idFactory()) != address(0), "Gateway check failed");
    }
}

// 3. Full Registry - interacts with both Gateway and Factory
contract FullRegistry is Ownable {
    IGateway public immutable gateway;
    IdFactory public immutable factory;
    
    constructor(address g, address f) {
        gateway = IGateway(g);
        factory = IdFactory(f);
        // Try Gateway
        require(address(gateway.idFactory()) == f, "Gateway factory mismatch");
        // Try Factory
        require(factory.owner() == address(gateway), "Factory ownership mismatch");
    }
}

// Test Contract
contract DeploymentTest is Test {
    address mockGateway;
    address mockFactory;
    address mockAuthority;
    
    function setUp() public {
        mockGateway = address(0x123);
        mockFactory = address(0x456);
        mockAuthority = address(0x789);
    }

    function testMinimalDeploy() public {
        MinimalRegistry reg = new MinimalRegistry(mockGateway, mockFactory, mockAuthority);
        assertEq(reg.gateway(), mockGateway);
        assertEq(reg.factory(), mockFactory);
        assertEq(reg.authority(), mockAuthority);
    }

    function testGatewayDeploy() public {
        // Deploy real Gateway first
        IdFactory realFactory = new IdFactory(mockAuthority);
        address[] memory signers = new address[](1);
        signers[0] = address(this);
        IGateway realGateway = IGateway(address(new Gateway(address(realFactory), signers)));
        
        // Test deployment with real Gateway
        GatewayRegistry reg = new GatewayRegistry(address(realGateway));
        assertEq(address(reg.gateway()), address(realGateway));
    }

    function testFullDeploy() public {
        // Deploy real components
        IdFactory realFactory = new IdFactory(mockAuthority);
        address[] memory signers = new address[](1);
        signers[0] = address(this);
        IGateway realGateway = IGateway(address(new Gateway(address(realFactory), signers)));
        
        // Transfer factory ownership to gateway
        realFactory.transferOwnership(address(realGateway));
        
        // Test full deployment
        FullRegistry reg = new FullRegistry(address(realGateway), address(realFactory));
        assertEq(address(reg.gateway()), address(realGateway));
        assertEq(address(reg.factory()), address(realFactory));
    }
} 