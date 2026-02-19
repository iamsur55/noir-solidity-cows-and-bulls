//SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {BaseZKHonkVerifier} from "../circuits/target/Verifier.sol";

contract CowsAndBulls {
    BaseZKHonkVerifier verifier;

    constructor(address _verifier) {
        verifier = BaseZKHonkVerifier(_verifier);
    }

    function playRound(
        bytes calldata proof,
        bytes32 guessA,
        bytes32 guessB,
        bytes32 guessC,
        bytes32 guessD,
        bytes32 hitCount,
        bytes32 blowCount,
        bytes32 publicSolutionHash
    ) public view returns (bool) {
        bytes32[] memory publicInputs = new bytes32[](7);

        publicInputs[0] = guessA;
        publicInputs[1] = guessB;
        publicInputs[2] = guessC;
        publicInputs[3] = guessD;
        publicInputs[4] = hitCount;
        publicInputs[5] = blowCount;
        publicInputs[6] = publicSolutionHash;

        require(verifier.verify(proof, publicInputs), "Invalid proof");

        // do something with hitCount

        return true;
    }
}
