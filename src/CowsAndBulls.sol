//SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {BaseZKHonkVerifier} from "../circuits/target/Verifier.sol";

contract CowsAndBulls {
    BaseZKHonkVerifier verifier;

    uint256 immutable MAX_ROUNDS = 12 - 1; //

    event NewGame(address breaker);
    event Guess(address maker, address breaker, bytes32 guessA, bytes32 guessB, bytes32 guessC, bytes32 guessD);
    event Feedback(address maker, address breaker, uint8 round, uint8 bulls, uint8 cows);

    event validated(address);

    constructor(address _verifier) {
        verifier = BaseZKHonkVerifier(_verifier);
    }

    mapping(address => mapping(address => game)) public games; // maps the maker to the breaker to the current game

    struct game {
        uint8 round;
        uint8 cows;
        uint8 bulls;
        bool breakerTurn;
        bytes32 guessA;
        bytes32 guessB;
        bytes32 guessC;
        bytes32 guessD;
    }

    function createNewGame(address breaker) external {
        game storage currentGame = games[msg.sender][breaker];
        // start a new game 
        require(currentGame.round == 0 || hasWinner(msg.sender, breaker));
        if(currentGame.round != 0) {
            require(hasWinner(msg.sender, breaker));
            currentGame.round = 0;
        } else {
            currentGame.breakerTurn = true;
        }
    }

    function makeGuess(
        address maker,
        bytes32 guessA, 
        bytes32 guessB, 
        bytes32 guessC, 
        bytes32 guessD
    ) external {
        require(!hasWinner(maker, msg.sender));
        game storage currentGame = games[maker][msg.sender];
        require(currentGame.breakerTurn);

        currentGame.guessA = guessA;
        currentGame.guessB = guessB;
        currentGame.guessC = guessC;
        currentGame.guessD = guessD;
        currentGame.breakerTurn = false;
        
        emit Guess(maker, msg.sender, guessA, guessB, guessC, guessD);
    }

    function giveFeedback(
        address breaker,
        bytes calldata proof,
        bytes32 cows,
        bytes32 bulls,
        bytes32 publicSolutionHash
    ) external {
        game storage currentGame = games[msg.sender][breaker];

        bytes32[] memory publicInputs = new bytes32[](7);

        publicInputs[0] = currentGame.guessA;
        publicInputs[1] = currentGame.guessB;
        publicInputs[2] = currentGame.guessC;
        publicInputs[3] = currentGame.guessD;
        publicInputs[4] = cows;
        publicInputs[5] = bulls;
        publicInputs[6] = publicSolutionHash;

        verify(proof, publicInputs);

        currentGame.round += 1;
        currentGame.bulls = uint8(uint256(bulls));
        currentGame.cows = uint8(uint256(cows));
        currentGame.breakerTurn = true;

        emit Feedback(msg.sender, breaker, currentGame.round, currentGame.bulls, currentGame.cows);
    }
 
    function hasWinner(address maker, address breaker) public view returns(bool) {
        game memory currentGame = games[maker][breaker];
        return (currentGame.bulls == 4 || currentGame.round == MAX_ROUNDS) ? true : false;
    }

    function verify(bytes memory proof, bytes32[] memory publicInputs) public view {
        require(verifier.verify(proof, publicInputs), "Invalid proof");
    }
}
