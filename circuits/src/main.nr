use dep::std;

fn compute_solution_hash(salt: u32, solutionA: u8, solutionB: u8, solutionC: u8, solutionD: u8) -> Field {
    std::hash::pedersen_hash([
        salt as Field,
        solutionA as Field,
        solutionB as Field,
        solutionC as Field,
        solutionD as Field,
    ])
}

fn main(
    guessA: pub u8,
    guessB: pub u8,
    guessC: pub u8,
    guessD: pub u8,
    numHit: pub u8,
    numBlow: pub u8,
    publicSolutionHash: pub Field,
    solutionA: u8,
    solutionB: u8,
    solutionC: u8,
    solutionD: u8,
    salt: u32
) {
    let guess: [u8; 4] = [guessA, guessB, guessC, guessD];
    let solutions: [u8; 4] = [solutionA, solutionB, solutionC, solutionD];

    // input validation. Each guess defined on the range [0,5] (6 colors)
    for i in 0..4 {
        assert(guess[i] <= 5);
        assert(solutions[i] <= 5);
    }
    
    let mut blow: u8 = 0; // correct color, wrong position
    let mut hit: u8 = 0; // correct color, right position
    
    for i in 0..4 {
        for j in 0..4 {
            if (guess[i] == solutions[j]) {
                if (i == j) {
                    hit = hit + 1;
                } else {
                    blow = blow + 1;
                }
            }
        }
    }

    assert(numBlow == blow);
    assert(numHit == hit);

    // you cannot validate the solution to this circuit, unless you know the salt
    let solutionHash: Field = compute_solution_hash(salt, solutionA, solutionB, solutionC, solutionD);

    assert(solutionHash == publicSolutionHash);
}
    
