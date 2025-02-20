// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
import "@onchain-id/solidity/contracts/Identity.sol";

/// @title Identity Factory for creating new OnchainID identities
/// @notice Handles the deployment of new identity contracts
contract IdentityFactory is Ownable {
    address public immutable implementationAuthority;
    
    event IdentityCreated(address indexed identity, address indexed owner);
    
    constructor(address _implementationAuthority) {
        require(_implementationAuthority != address(0), "Invalid implementation authority");
        implementationAuthority = _implementationAuthority;
    }
    
    /// @notice Creates a new identity for a user
    /// @param owner The address that will own the identity
    /// @return The address of the new identity contract
    function createIdentity(address owner) external returns (address) {
        // Create new identity using OnchainID implementation
        Identity newIdentity = new Identity(
            owner,
            false // Not a master identity
        );
        
        emit IdentityCreated(address(newIdentity), owner);
        return address(newIdentity);
    }
}

/// @title Registry for managing OnchainID identities
/// @notice Tracks verified identities and their accreditation status
contract IdentityRegistry is Ownable {
    struct IdentityInfo {
        address identityContract;    // Address of the OnchainID contract
        bool isAccredited;          // Accreditation status
        uint256 lastVerified;       // Timestamp of last verification
        uint256[] claimTopics;      // List of required claim topics
    }
    
    mapping(address => IdentityInfo) public identities;
    mapping(address => bool) public trustedIssuers;
    mapping(uint256 => bool) public validClaimTopics;
    
    IdentityFactory public immutable factory;
    
    event IdentityRegistered(address indexed user, address indexed identityContract);
    event AccreditationUpdated(address indexed user, bool status);
    event IssuerTrustUpdated(address indexed issuer, bool trusted);
    event ClaimTopicUpdated(uint256 indexed topic, bool valid);
    
    constructor(address _factory) {
        require(_factory != address(0), "Invalid factory address");
        factory = IdentityFactory(_factory);
    }
    
    /// @notice Registers a new identity for a user
    /// @param user The address of the user
    /// @param claimTopics Array of required claim topics
    function registerIdentity(address user, uint256[] calldata claimTopics) external onlyOwner {
        require(identities[user].identityContract == address(0), "Identity already registered");
        
        // Create new identity through factory
        address identityContract = factory.createIdentity(user);
        
        identities[user] = IdentityInfo({
            identityContract: identityContract,
            isAccredited: false,
            lastVerified: 0,
            claimTopics: claimTopics
        });
        
        emit IdentityRegistered(user, identityContract);
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