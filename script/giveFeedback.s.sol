// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console2} from "lib/forge-std/src/console2.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";
import {Helper} from "./helper/Helper.sol";

contract GiveFeedbackScript is Helper {
    function run() public {
        address cowsAndBullsAddress = getLatestDeploymentAddress();
        CowsAndBulls cowsAndBulls = CowsAndBulls(cowsAndBullsAddress);

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

        address breaker = vm.parseTomlAddress(vm.readFile("Game.toml"), ".breakerAddress");
        console2.log("cows");
        console2.logBytes32(publicInputs[4]);
        console2.log("bulls");
        console2.logBytes32(publicInputs[5]);
        console2.logBytes32(publicInputs[6]);

        vm.startBroadcast();
        cowsAndBulls.giveFeedback(
            breaker,
            proof,
            publicInputs[4],
            publicInputs[5],
            publicInputs[6]
        );
        vm.stopBroadcast();
    }
}
