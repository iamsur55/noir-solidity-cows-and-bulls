// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "lib/forge-std/src/Script.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";
import {HonkVerifier} from "circuits/target/Verifier.sol";

contract CowsAndBullsScript is Script {
    HonkVerifier public verifier;
    CowsAndBulls public cowsAndBulls;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        verifier = new HonkVerifier();

        cowsAndBulls = new CowsAndBulls(address(verifier));

        vm.stopBroadcast();
    }
}
