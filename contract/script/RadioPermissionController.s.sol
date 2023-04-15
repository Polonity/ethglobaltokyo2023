// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {RadioPermissionController} from "../src/RadioPermissionController.sol";

contract RadioPermissionControllerScript is Script {
    function setUp() public {}

    function run() public {
        address physicalAssetAddress = address(0x987A29D57679D0B2d98aC53f3d2c2A786716831C);
        string memory physicalAssetPublicKey = 
                "3b3f9b38988da8941bf98c44791e42d92bfea57a7cc371c6740d5d68d71f2f6b"
                "0c3dab7179a1ba434cab6d52edc227e98aefd90d9a8615a68e92c94ce0025af3";
        vm.broadcast();
        RadioPermissionController controller = new RadioPermissionController(
            physicalAssetAddress, 
            physicalAssetPublicKey
        );
    }
}
