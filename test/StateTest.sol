// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/IdentityRegistry.sol";
import "@onchain-id/solidity/contracts/gateway/Gateway.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";

contract StateTest is Test {
    Gateway gateway;
    IdFactory factory;
    ImplementationAuthority authority;
    IdentityRegistry registry;
    
    function setUp() public {
        // Deploy dependencies
        authority = new ImplementationAuthority(address(1));
        factory = new IdFactory(address(authority));
        
        address[] memory signers = new address[](1);
        signers[0] = address(this);
        gateway = new Gateway(address(factory), signers);
    }

    function testStateInitialization() public {
        registry = new IdentityRegistry(
            address(gateway),
            address(factory),
            address(authority)
        );
        
        // Check immutable state
        assertEq(address(registry._gateway()), address(gateway), "Gateway not initialized");
        assertEq(registry._factory(), address(factory), "Factory not initialized");
        assertEq(registry._implementationAuthority(), address(authority), "Authority not initialized");
        
        // Check ownership
        assertEq(registry.owner(), address(this), "Owner not initialized");
        
        // Check initial mappings state
        address randomUser = address(0x123);
        assertFalse(registry.trustedIssuers(randomUser), "Issuer should not be trusted");
        assertFalse(registry.validClaimTopics(1), "Topic should not be valid");
    }
} 