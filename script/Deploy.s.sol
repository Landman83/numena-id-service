// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@onchain-id/solidity/contracts/Identity.sol";
import "@onchain-id/solidity/contracts/gateway/Gateway.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
import "../src/IdentityRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Identity Implementation
        Identity identityImplementation = new Identity(
            address(this),  // temporary owner
            true           // This is the master/implementation copy
        );

        // 2. Deploy Implementation Authority
        ImplementationAuthority authority = new ImplementationAuthority(
            address(identityImplementation)
        );

        // 3. Deploy Identity Factory
        IdFactory factory = new IdFactory(address(authority));

        // 4. Deploy Gateway with Factory
        address[] memory initialSigners = new address[](1);
        initialSigners[0] = msg.sender; // Add deployer as initial signer
        Gateway gateway = new Gateway(
            address(factory),
            initialSigners
        );

        // 5. Transfer Factory ownership to Gateway
        factory.transferOwnership(address(gateway));

        console.log("Implementation Authority:", address(authority));
        console.log("Identity Factory:", address(factory));
        console.log("Gateway:", address(gateway));

        // 6. Testing Gateway
        console.log("\nTesting Gateway...");
        try gateway.idFactory() returns (IdFactory factoryAddr) {
            console.log("Gateway's factory address:", address(factoryAddr));
            require(address(factoryAddr) == address(factory), "Gateway factory mismatch");
            
            // Test if Gateway recognizes our signer
            bool isSigner = gateway.approvedSigners(msg.sender);
            console.log("Is deployer approved signer?", isSigner);
            require(isSigner, "Deployer not recognized as signer");
            
            // Test if Gateway recognizes factory ownership
            address factoryOwner = factory.owner();
            console.log("Factory owner:", factoryOwner);
            require(factoryOwner == address(gateway), "Factory not owned by Gateway");
        } catch {
            console.log("Failed to query Gateway state");
            revert("Gateway initialization failed");
        }

        // After each deployment
        console.log("\nDeployment Order:");
        console.log("1. Identity Implementation at:", address(identityImplementation));
        console.log("2. Implementation Authority at:", address(authority));
        console.log("3. Factory at:", address(factory));
        console.log("4. Gateway at:", address(gateway));
        
        // Before Registry deployment
        console.log("\nVerifying contract states:");
        console.log("- Factory owner:", factory.owner());
        console.log("- Gateway factory:", address(gateway.idFactory()));

        // 7. Deploy our Registry
        console.log("\nDeployer address:", msg.sender);
        console.log("Contract addresses:");
        console.log("- Gateway:", address(gateway));
        console.log("- Factory:", address(factory));
        console.log("- Authority:", address(authority));
        
        require(address(gateway) != address(0), "Gateway is zero address");
        require(address(factory) != address(0), "Factory is zero address");
        require(address(authority) != address(0), "Authority is zero address");
        
        try new IdentityRegistry(
            address(gateway),
            address(factory),
            address(authority)
        ) returns (IdentityRegistry registry) {
            console.log("\nRegistry successfully deployed at:", address(registry));
        } catch Error(string memory reason) {
            console.log("\nFailed to deploy Registry:", reason);
        } catch (bytes memory) {
            console.log("\nFailed to deploy Registry (no reason given)");
        }

        vm.stopBroadcast();
    }
} 