// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "lib/forge-std/src/Script.sol";
import {console2} from "lib/forge-std/src/console2.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";

contract PlayRoundScript is Script {
    function run() public {
        string memory deploymentJson = vm.readFile("broadcast/CowsAndBulls.s.sol/31337/run-latest.json");

        string memory contractName = vm.parseJsonString(deploymentJson, ".transactions[2].contractName");
        require(
            keccak256(bytes(contractName)) == keccak256(bytes("CowsAndBulls")), "CowsAndBulls tx not found at index 2"
        );
        address cowsAndBullsAddress = vm.parseJsonAddress(deploymentJson, ".transactions[2].contractAddress");

        bytes memory proof = vm.readFileBinary("circuits/target/proof");
        bytes memory raw = vm.readFileBinary("circuits/target/public_inputs");

        require(raw.length >= 7 * 32, "public_inputs too short");

        bytes32[] memory publicInputs = new bytes32[](7);
        for (uint256 i = 0; i < 7; i++) {
            bytes32 value;
            assembly {
                value := mload(add(add(raw, 0x20), mul(i, 0x20)))
            }
            publicInputs[i] = value;
        }

        CowsAndBulls cowsAndBulls = CowsAndBulls(cowsAndBullsAddress);

        vm.startBroadcast();
        bool ok = cowsAndBulls.playRound(
            proof,
            publicInputs[0],
            publicInputs[1],
            publicInputs[2],
            publicInputs[3],
            publicInputs[4],
            publicInputs[5],
            publicInputs[6]
        );
        vm.stopBroadcast();

        console2.log("playRound result:", ok);
    }
}
