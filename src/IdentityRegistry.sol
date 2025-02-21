// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";
import "./interfaces/IIdentityRegistry.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
import "@onchain-id/solidity/contracts/Identity.sol";
import "./interfaces/IGateway.sol";

/// @title Registry for managing OnchainID identities using Gateway deployment
contract IdentityRegistry is Ownable {
    struct IdentityInfo {
        address identityContract;    // Address of the OnchainID contract
        bool isAccredited;          // Accreditation status
        uint256 lastVerified;       // Timestamp of last verification
        uint256[] claimTopics;      // List of required claim topics
    }
    
    IGateway public immutable _gateway;
    address public immutable _factory;
    address public immutable _implementationAuthority;
    
    mapping(address => IdentityInfo) public identities;
    mapping(address => bool) public trustedIssuers;
    mapping(uint256 => bool) public validClaimTopics;
    
    event IdentityRegistered(address indexed user, address indexed identityContract);
    event AccreditationUpdated(address indexed user, bool status);
    event IssuerTrustUpdated(address indexed issuer, bool trusted);
    event ClaimTopicUpdated(uint256 indexed topic, bool valid);
    event DebugConstructor(address gateway, address factory, address authority);
    
    constructor(
        address gatewayAddress,
        address factoryAddress,
        address authorityAddress
    ) Ownable() {
        require(gatewayAddress != address(0), "1: Invalid gateway address");
        require(factoryAddress != address(0), "2: Invalid factory address");
        require(authorityAddress != address(0), "3: Invalid implementation authority");
        
        _factory = factoryAddress;
        _implementationAuthority = authorityAddress;
        _gateway = IGateway(gatewayAddress);
        
        emit DebugConstructor(gatewayAddress, factoryAddress, authorityAddress);
    }
    
    /// @notice Registers a new identity for a user using the Gateway
    /// @param user The address of the user
    /// @param claimTopics Array of required claim topics
    function registerIdentity(address user, uint256[] calldata claimTopics) external {
        require(identities[user].identityContract == address(0), "Identity already registered");
        
        // Compute the expected identity address before deployment
        bytes32 salt = bytes32(uint256(uint160(user)));
        address expectedIdentity = _computeExpectedAddress(user, salt);
        
        // Deploy identity through gateway
        _gateway.deployIdentityForWallet(user);
        
        identities[user] = IdentityInfo({
            identityContract: expectedIdentity,
            isAccredited: false,
            lastVerified: 0,
            claimTopics: claimTopics
        });
        
        emit IdentityRegistered(user, expectedIdentity);
    }
    
    /// @notice Computes the expected identity address using CREATE2
    function _computeExpectedAddress(address owner, bytes32 salt) internal view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                _factory,
                salt,
                keccak256(abi.encodePacked(
                    type(Identity).creationCode,
                    abi.encode(owner, false)
                ))
            )
        );
        return address(uint160(uint256(hash)));
    }
    
    /// @notice Verifies claims for an identity
    /// @param user The address of the user to verify
    function verifyIdentity(address user) external {
        IdentityInfo storage info = identities[user];
        require(info.identityContract != address(0), "Identity not registered");
        
        IIdentity identity = IIdentity(info.identityContract);
        bool allClaimsValid = true;
        
        // Check each required claim topic
        for (uint256 i = 0; i < info.claimTopics.length; i++) {
            require(validClaimTopics[info.claimTopics[i]], "Invalid claim topic");
            
            bytes32[] memory claimIds = identity.getClaimIdsByTopic(info.claimTopics[i]);
            bool topicValid = false;
            
            for (uint256 j = 0; j < claimIds.length; j++) {
                (uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri) = 
                    identity.getClaim(claimIds[j]);
                
                if (trustedIssuers[issuer]) {
                    IClaimIssuer claimIssuer = IClaimIssuer(issuer);
                    if (claimIssuer.isClaimValid(IIdentity(info.identityContract), topic, signature, data)) {
                        topicValid = true;
                        break;
                    }
                }
            }
            
            if (!topicValid) {
                allClaimsValid = false;
                break;
            }
        }
        
        info.isAccredited = allClaimsValid;
        info.lastVerified = block.timestamp;
        
        emit AccreditationUpdated(user, allClaimsValid);
    }
    
    /// @notice Adds or removes a trusted claim issuer
    /// @param issuer The address of the claim issuer
    /// @param trusted Whether to trust or untrust the issuer
    function setTrustedIssuer(address issuer, bool trusted) external onlyOwner {
        require(issuer != address(0), "Invalid issuer address");
        trustedIssuers[issuer] = trusted;
        emit IssuerTrustUpdated(issuer, trusted);
    }
    
    /// @notice Sets whether a claim topic is valid
    /// @param topic The claim topic number
    /// @param valid Whether the topic is valid
    function setClaimTopic(uint256 topic, bool valid) external onlyOwner {
        validClaimTopics[topic] = valid;
        emit ClaimTopicUpdated(topic, valid);
    }
    
    /// @notice Checks if a user's identity is accredited
    /// @param user The address to check
    /// @return bool Whether the identity is accredited
    function isAccredited(address user) external view returns (bool) {
        return identities[user].isAccredited;
    }
    
    /// @notice Gets an identity's contract address
    /// @param user The address to look up
    /// @return The identity contract address
    function getIdentityContract(address user) external view returns (address) {
        return identities[user].identityContract;
    }
}