// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {CowsAndBulls} from "../src/CowsAndBulls.sol";
import {HonkVerifier} from "../circuits/target/Verifier.sol";

contract CowsAndBullsTest is Test {
    HonkVerifier public verifier;
    CowsAndBulls public cowsAndBulls;

    address constant MAKER = address(0);
    address BREAKER = address(1);

    function setUp() public {
        verifier = new HonkVerifier();
        cowsAndBulls = new CowsAndBulls(address(verifier));
    }
    function test_createNewGame() public {
        vm.prank(MAKER);
        cowsAndBulls.createNewGame(BREAKER);
        (uint8 round, uint8 bulls, uint8 cows, bool breakerTurn, bytes32 guessA, bytes32 guessB, bytes32 guessC, bytes32 guessD) = cowsAndBulls.games(MAKER, BREAKER);
        vm.assertTrue(breakerTurn);
    }

    function test_makeGuess() public {
        vm.prank(MAKER);
        cowsAndBulls.createNewGame(BREAKER);

        vm.prank(BREAKER);
        (bytes32 guessA, bytes32 guessB, bytes32 guessC, bytes32 guessD) = makeGuess();
        (uint8 round, uint8 cows, uint8 bulls, bool breakerTurn, bytes32 guessA_, bytes32 guessB_, bytes32 guessC_, bytes32 guessD_) = cowsAndBulls.games(MAKER, BREAKER);

        vm.assertEq(guessA, guessA_);
        vm.assertEq(guessB, guessB_);
        vm.assertEq(guessC, guessC_);
        vm.assertEq(guessD, guessD_);
        vm.assertFalse(breakerTurn);
        vm.assertEq(round, 0);
    }

    function test_giveFeedback() public {
        vm.prank(MAKER);
        cowsAndBulls.createNewGame(BREAKER);

        vm.prank(BREAKER);
        makeGuess();

        vm.prank(MAKER);
        (bytes32 cows, bytes32 bulls) = giveFeedback();
        
        (uint8 round, uint8 cows_, uint8 bulls_, bool breakerTurn, bytes32 guessA_, bytes32 guessB_, bytes32 guessC_, bytes32 guessD_) = cowsAndBulls.games(MAKER, BREAKER);

        vm.assertTrue(bytes32(uint256(bulls_)) == bulls);
        vm.assertTrue(bytes32(uint256(cows_)) == cows);
    }

    function test_hasWinner() public {
 
    }

    function test_verify() public {

    }

    function makeGuess() public returns(bytes32, bytes32, bytes32, bytes32) {
        bytes32 guessA = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".guessA");
        bytes32 guessB = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".guessB");
        bytes32 guessC = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".guessC");
        bytes32 guessD = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".guessD");

        cowsAndBulls.makeGuess(MAKER, guessA, guessB, guessC, guessD);

        return (guessA, guessB, guessC, guessD);
    }

    function giveFeedback() public returns(bytes32, bytes32) {

        bytes memory proof = vm.parseJsonBytes(vm.readFile("test/inputs.json"), ".proof");
        bytes32 cows = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".cows");
        bytes32 bulls = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".bulls");
        bytes32 publicSolutionHash = vm.parseJsonBytes32(vm.readFile("test/inputs.json"), ".publicSolutionHash");
        
        cowsAndBulls.giveFeedback(BREAKER, proof, cows, bulls, publicSolutionHash);

        return(cows, bulls);
    }
}
