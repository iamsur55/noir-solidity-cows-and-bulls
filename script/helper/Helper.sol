// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "lib/forge-std/src/Script.sol";
import {console2} from "lib/forge-std/src/console2.sol";
import {CowsAndBulls} from "../../src/CowsAndBulls.sol";

contract Helper is Script {
    function getLatestDeploymentAddress() public view returns(address) {
        string memory deploymentJson = vm.readFile("broadcast/CowsAndBulls.s.sol/31337/run-latest.json");
        
        string memory contractName = vm.parseJsonString(deploymentJson, string.concat(".transactions[0].contractName"));
        if(keccak256(bytes(contractName)) == keccak256(bytes("CowsAndBulls"))) {
           return vm.parseJsonAddress(deploymentJson, string.concat(".transactions[0].contractAddress")); 
        } 

        contractName = vm.parseJsonString(deploymentJson, string.concat(".transactions[1].contractName"));
        if(keccak256(bytes(contractName)) == keccak256(bytes("CowsAndBulls"))) {
            return vm.parseJsonAddress(deploymentJson, string.concat(".transactions[1].contractAddress")); 
        } 
        
        contractName = vm.parseJsonString(deploymentJson, string.concat(".transactions[2].contractName"));
        if(keccak256(bytes(contractName)) == keccak256(bytes("CowsAndBulls"))) {
            return vm.parseJsonAddress(deploymentJson, string.concat(".transactions[2].contractAddress")); 
        }
    }
}
