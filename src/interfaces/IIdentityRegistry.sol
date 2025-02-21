// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IIdentityRegistry {
    struct IdentityInfo {
        address identityContract;
        bool isAccredited;
        uint256 lastVerified;
        uint256[] claimTopics;
    }

    event IdentityRegistered(address indexed user, address indexed identityContract);
    event AccreditationUpdated(address indexed user, bool status);
    event IssuerTrustUpdated(address indexed issuer, bool trusted);
    event ClaimTopicUpdated(uint256 indexed topic, bool valid);

    function registerIdentity(address user, uint256[] calldata claimTopics) external;
    function verifyIdentity(address user) external;
    function setTrustedIssuer(address issuer, bool trusted) external;
    function setClaimTopic(uint256 topic, bool valid) external;
    function isAccredited(address user) external view returns (bool);
    function getIdentityContract(address user) external view returns (address);
    function identities(address user) external view returns (IdentityInfo memory);
    function trustedIssuers(address issuer) external view returns (bool);
    function validClaimTopics(uint256 topic) external view returns (bool);
}