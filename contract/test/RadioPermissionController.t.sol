// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {RadioPermissionController} from "../src/RadioPermissionController.sol";

contract RadioPermissionControllerTest is Test {
    RadioPermissionController controller;

    string m_physicalAssetPublicKey = 
            "3b3f9b38988da8941bf98c44791e42d92bfea57a7cc371c6740d5d68d71f2f6b"
            "0c3dab7179a1ba434cab6d52edc227e98aefd90d9a8615a68e92c94ce0025af3";
    address m_physicalAssetAddress = address(0x987A29D57679D0B2d98aC53f3d2c2A786716831C);

    function setUp() public {
        controller = new RadioPermissionController(
            m_physicalAssetAddress, 
            m_physicalAssetPublicKey
        );
    }

    function testStartEngagement() public {
        // user
        address userAddress = address(0x10);

        // Today This is the user's address.
        uint256 _tokenId = uint256(uint160(userAddress));
        uint256 _dataEngagement = 0;
        uint256 _hashK_UA = 0x5648b95c3018e84633066f241765c431a4dd52bf0584c1a95a6e40c779b96cf7;
        controller.startUserEngagement(
            _tokenId, 
            _dataEngagement, 
            _hashK_UA
        );

        uint256 _hashK_A = controller.getHashK_A(_tokenId);
        uint256 _hashK_UA2 = controller.gethashK_UA(_tokenId);
        assertEq(_hashK_A, 0);
        assertEq(_hashK_UA2, _hashK_UA);

    }

    function testUserEngagement() public{
        uint256 _tokenId = uint256(uint160(address(msg.sender)));
        uint256 _dataEngagement = 0;
        uint256 _hashK_UA = 0x5648b95c3018e84633066f241765c431a4dd52bf0584c1a95a6e40c779b96cf7;
        controller.startUserEngagement(
            _tokenId, 
            _dataEngagement, 
            _hashK_UA
        );

        uint256 _hashK_A = 0x5648b95c3018e84633066f241765c431a4dd52bf0584c1a95a6e40c779b96cf7;
        uint256 _hashK_UA2 = 0x5648b95c3018e84633066f241765c431a4dd52bf0584c1a95a6e40c779b96cf7;
        
        vm.startPrank(m_physicalAssetAddress);
        controller.userEngagement(
            msg.sender, 
            _hashK_A
        );
        vm.stopPrank();

        uint256 _hashK_A2 = controller.getHashK_A(_tokenId);
        uint256 _hashK_UA3 = controller.gethashK_UA(_tokenId);
        assertEq(_hashK_A2, _hashK_A);
        assertEq(_hashK_UA3, _hashK_UA2);
    }

}
