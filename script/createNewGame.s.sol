// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console2} from "lib/forge-std/src/console2.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";
import {Helper} from "./helper/Helper.sol";

contract CreateNewGameScript is Helper {
    function run() public {
        
        address cowsAndBullsAddress = getLatestDeploymentAddress();

        CowsAndBulls cowsAndBulls = CowsAndBulls(cowsAndBullsAddress);

        address breaker = vm.parseTomlAddress(vm.readFile("Game.toml"), ".breakerAddress");

        vm.startBroadcast();
        cowsAndBulls.createNewGame(
            breaker
        );
        vm.stopBroadcast();
    }
}
