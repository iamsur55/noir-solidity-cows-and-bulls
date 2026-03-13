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

    struct ProofInputs {
        bytes proof;
        bytes32 guessA;
        bytes32 guessB;
        bytes32 guessC;
        bytes32 guessD;
        bytes32 cows;
        bytes32 bulls;
        bytes32 publicSolutionHash;
    }

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
        ProofInputs memory inputs = loadProofInputs();
        cowsAndBulls.makeGuess(MAKER, inputs.guessA, inputs.guessB, inputs.guessC, inputs.guessD);
        return (inputs.guessA, inputs.guessB, inputs.guessC, inputs.guessD);
    }

    function giveFeedback() public returns(bytes32, bytes32) {
        ProofInputs memory inputs = loadProofInputs();
        cowsAndBulls.giveFeedback(BREAKER, inputs.proof, inputs.cows, inputs.bulls, inputs.publicSolutionHash);
        return (inputs.cows, inputs.bulls);
    }

    function loadProofInputs() internal returns (ProofInputs memory) {
        bytes memory publicInputs = vm.readFileBinary("circuits/target/public_inputs");
        return ProofInputs({
            proof: vm.readFileBinary("circuits/target/proof"),
            guessA: readBytes32(publicInputs, 0),
            guessB: readBytes32(publicInputs, 32),
            guessC: readBytes32(publicInputs, 64),
            guessD: readBytes32(publicInputs, 96),
            cows: readBytes32(publicInputs, 128),
            bulls: readBytes32(publicInputs, 160),
            publicSolutionHash: readBytes32(publicInputs, 192)
        });
    }

    function readBytes32(bytes memory data, uint256 offset) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(add(data, 32), offset))
        }
    }
}
