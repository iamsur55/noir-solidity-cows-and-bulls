// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";
import {HonkVerifier} from "../circuits/target/Verifier.sol";

contract CowsAndBullsTest is Test {
    HonkVerifier public verifier;
    CowsAndBulls public cowsAndBulls;

    function setUp() public {
        verifier = new HonkVerifier();
        cowsAndBulls = new CowsAndBulls(address(verifier));
    }

    function test_PlayRound() public {
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

        assertTrue(ok);
    }
}
