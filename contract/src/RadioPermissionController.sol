// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

contract RadioPermissionController is Context{
    // Token states and other data structures would be defined here.
    // Implement the required data structures based on your requirements.
    // For example:
    // - mappings for storing token states
    // - mappings for storing user assignments
    // - mappings for storing asset addresses
    // - mappings for storing user and owner engagement data
    // - mappings for storing timeout values and timestamps
    struct UserEngagement {
        uint256 dataEngagement;
        uint256 hashK_UA;
        uint256 hashK_A;
        uint256 timeout;
        uint256 timestamp;
        address addressUser;
    }
    
    /// @dev Mapping from token ID to token data.
    mapping (uint256 => UserEngagement) public userEngagements;

    /// @dev Mapping from address to token ID 
    mapping (address => uint256) public assetAddresses;
    
    /// @dev address of the physical asset
    address public addressOfAsset;

    /// @dev public key XY point of the physical asset
    string public publicKeyOfAsset;

    uint256 constant timeout = 600; // 10 minutes

    constructor(address addressOfAsset_, string memory publicKeyOfAsset_  ) {
        addressOfAsset = addressOfAsset_;
        publicKeyOfAsset = publicKeyOfAsset_;
    }

    function getHashK_A(uint256 _tokenId) public view returns (uint256) {
        return userEngagements[_tokenId].hashK_A;
    }
    function gethashK_UA(uint256 _tokenId) public view returns (uint256) {
        return userEngagements[_tokenId].hashK_UA;
    }

    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // ERC4519 functions
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Starts the user engagement process.
    /// This function is called by the user to start the user engagement process.
    /// @param _tokenId The token ID of the physical asset. (*1) Today This is the user's address.
    /// @param _dataEngagement The data engagement value.
    /// @param _hashK_UA The hash of the user's shared key.
    function startUserEngagement(uint256 _tokenId, uint256 _dataEngagement, uint256 _hashK_UA) external payable  {
        address userAddress = address(uint160(_tokenId));

        if (userEngagements[_tokenId].timestamp + userEngagements[_tokenId].timeout < block.timestamp) {
            userEngagements[_tokenId].timestamp = block.timestamp;
        }
        // else{
        //     revert("User engagement timeout not expired");
        // }
        
        userEngagements[_tokenId].dataEngagement = _dataEngagement;
        userEngagements[_tokenId].hashK_UA = _hashK_UA;
        userEngagements[_tokenId].addressUser = userAddress;
        userEngagements[_tokenId].timeout = timeout;
        assetAddresses[userAddress] = _tokenId;
    }

    /// @dev Completes the user engagement process.
    /// This function is called by the device to complete the user engagement process.
    function userEngagement(address user, uint256 _hashK_A) external payable  {
        if(addressOfAsset != _msgSender()){
            revert("Not physical asset");
        }
        uint256 tokenId = tokenFromBCA(user);
        if(userEngagements[tokenId].hashK_UA != _hashK_A){
            revert("HashK_UA does not match");
        }
        userEngagements[tokenId].hashK_A = _hashK_A;
        userEngagements[tokenId].timestamp = block.timestamp;
    }

    function tokenFromBCA(address _addressAsset) public view  returns (uint256) {
        return assetAddresses[_addressAsset];
    }

    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Implement the required functions from the IERC4519 interface here.

    function setUser(uint256 _tokenId, address _addressUser) external payable  {
        // Implement the setUser function
        revert("Not implemented");
    }

    function startOwnerEngagement(uint256 _tokenId, uint256 _dataEngagement, uint256 _hashK_OA) external payable  {
        // Implement the startOwnerEngagement function
        revert("Not implemented");
    }

    function ownerEngagement(uint256 _hashK_A) external payable  {
        // Implement the ownerEngagement function
        revert("Not implemented");
    }

    function checkTimeout(uint256 _tokenId) external  returns (bool) {
        // Implement the checkTimeout function
        revert("Not implemented");
    }

    function setTimeout(uint256 _tokenId, uint256 _timeout) external  {
        // Implement the setTimeout function
        revert("Not implemented");
    }

    function updateTimestamp() external  {
        // Implement the updateTimestamp function
        revert("Not implemented");
    }

    function ownerOfFromBCA(address _addressAsset) external view  returns (address) {
        // Implement the ownerOfFromBCA function
        revert("Not implemented");
    }

    function userOf(uint256 _tokenId) external view  returns (address) {
        // Implement the userOf function
        revert("Not implemented");
    }

    function userOfFromBCA(address _addressAsset) external view  returns (address) {
        // Implement the userOfFromBCA function
        revert("Not implemented");
    }

    function userBalanceOf(address _addressUser) external view  returns (uint256) {
        // Implement the userBalanceOf function
        revert("Not implemented");
    }

    function userBalanceOfAnOwner(address _addressUser, address _addressOwner) external view  returns (uint256) {
        // Implement the userBalanceOf
        revert("Not implemented");
    }

}
