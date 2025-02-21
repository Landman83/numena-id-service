// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../src/interfaces/IGateway.sol";

// Current layout
contract RegistryV1 is Ownable {
    IGateway public immutable _gateway;
    address public immutable _factory;
    address public immutable _implementationAuthority;
    
    constructor(address gateway, address factory, address authority) {
        _gateway = IGateway(gateway);
        _factory = factory;
        _implementationAuthority = authority;
    }
}

// Alternative layout (grouped by type)
contract RegistryV2 is Ownable {
    // Addresses first
    address public immutable _factory;
    address public immutable _implementationAuthority;
    // Interfaces last
    IGateway public immutable _gateway;
    
    constructor(address gateway, address factory, address authority) {
        _factory = factory;
        _implementationAuthority = authority;
        _gateway = IGateway(gateway);
    }
}

contract LayoutTest is Test {
    address mockGateway;
    address mockFactory;
    address mockAuthority;
    
    function setUp() public {
        mockGateway = address(0x123);
        mockFactory = address(0x456);
        mockAuthority = address(0x789);
    }

    function testStorageLayout() public {
        // Deploy both versions
        RegistryV1 v1 = new RegistryV1(mockGateway, mockFactory, mockAuthority);
        RegistryV2 v2 = new RegistryV2(mockGateway, mockFactory, mockAuthority);
        
        // Compare state
        assertEq(address(v1._gateway()), address(v2._gateway()), "Gateway mismatch");
        assertEq(v1._factory(), v2._factory(), "Factory mismatch");
        assertEq(v1._implementationAuthority(), v2._implementationAuthority(), "Authority mismatch");
        
        // Compare gas costs (using view functions to test storage access)
        uint256 gasV1 = gasleft();
        v1._gateway();
        uint256 gasUsedV1 = gasV1 - gasleft();
        
        uint256 gasV2 = gasleft();
        v2._gateway();
        uint256 gasUsedV2 = gasV2 - gasleft();
        
        console.log("Gas used V1:", gasUsedV1);
        console.log("Gas used V2:", gasUsedV2);
    }
} 