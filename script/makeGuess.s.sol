// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console2} from "lib/forge-std/src/console2.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";
import {Helper} from "./helper/Helper.sol";

contract MakeGuessScript is Helper {
    function run() public {
        address cowsAndBullsAddress = getLatestDeploymentAddress();
        CowsAndBulls cowsAndBulls = CowsAndBulls(cowsAndBullsAddress);

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

        address maker = vm.parseTomlAddress(vm.readFile("Game.toml"), ".makerAddress");

        vm.startBroadcast();
        cowsAndBulls.makeGuess(
            maker,
            publicInputs[0],
            publicInputs[1],
            publicInputs[2],
            publicInputs[3]
        );
        vm.stopBroadcast();
    }
}
