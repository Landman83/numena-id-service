// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/factory/IdFactory.sol";

interface IGateway {
    event SignerApproved(address indexed signer);
    event SignerRevoked(address indexed signer);
    event SignatureRevoked(bytes indexed signature);
    event SignatureApproved(bytes indexed signature);

    function idFactory() external view returns (IdFactory);
    function approvedSigners(address) external view returns (bool);
    function revokedSignatures(bytes calldata) external view returns (bool);
    
    function deployIdentityForWallet(address wallet) external returns (address);
    function getIdentityForWallet(address wallet) external view returns (address);
    
    function approveSigner(address signer) external;
    function revokeSigner(address signer) external;
    function revokeSignature(bytes calldata signature) external;
    function approveSignature(bytes calldata signature) external;
    
    function deployIdentityWithSalt(
        address identityOwner,
        string memory salt,
        uint256 signatureExpiry,
        bytes calldata signature
    ) external returns (address);
}