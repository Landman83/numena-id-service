// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/interfaces/IGateway.sol";
import "@onchain-id/solidity/contracts/gateway/Gateway.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";

contract InterfaceTest is Test {
    function testGatewayInterface() public pure {
        // Just test the interface selectors
        bytes4 expectedSelector = bytes4(keccak256("deployIdentityForWallet(address)"));
        bytes4 actualSelector = Gateway.deployIdentityForWallet.selector;
        require(actualSelector == expectedSelector, "Selector mismatch");
    }
} 