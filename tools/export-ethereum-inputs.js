const fs = require('fs');
const path = require('path');

function resolveFromWorkspace(relPathFromRoot, relPathFromCircuits) {
  const cwd = process.cwd();

  const candidateRoot = path.resolve(cwd, relPathFromRoot);
  const candidateCircuits = path.resolve(cwd, relPathFromCircuits);

  if (fs.existsSync(candidateRoot)) return candidateRoot;
  if (fs.existsSync(candidateCircuits)) return candidateCircuits;

  throw new Error(`Could not find file. Tried: ${candidateRoot} and ${candidateCircuits}`);
}

function resolveOutputPath(relPathFromRoot, relPathFromCircuits) {
  const cwd = process.cwd();

  const candidateRoot = path.resolve(cwd, relPathFromRoot);
  const candidateCircuits = path.resolve(cwd, relPathFromCircuits);

  const rootDir = path.dirname(candidateRoot);
  if (fs.existsSync(rootDir)) return candidateRoot;

  const circuitsDir = path.dirname(candidateCircuits);
  if (fs.existsSync(circuitsDir)) return candidateCircuits;

  throw new Error(`Could not find output directory. Tried: ${rootDir} and ${circuitsDir}`);
}

function toBytes32Hex(bufferChunk) {
  if (bufferChunk.length !== 32) {
    throw new Error(`Expected 32 bytes, got ${bufferChunk.length}`);
  }
  return `0x${bufferChunk.toString('hex')}`;
}

function main() {
  try {
    const proofPath = resolveFromWorkspace('circuits/target/proof', 'target/proof');
    const publicInputsPath = resolveFromWorkspace('circuits/target/public_inputs', 'target/public_inputs');

    const proof = fs.readFileSync(proofPath);
    const rawPublicInputs = fs.readFileSync(publicInputsPath);

    if (rawPublicInputs.length < 7 * 32) {
      throw new Error(`public_inputs too short: got ${rawPublicInputs.length} bytes, need at least ${7 * 32}`);
    }

    const publicInputs = [];
    for (let i = 0; i < 7; i++) {
      const start = i * 32;
      const end = start + 32;
      publicInputs.push(toBytes32Hex(rawPublicInputs.subarray(start, end)));
    }

    const payload = {
      contractFunction: 'playRound(bytes,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)',
      proof: `0x${proof.toString('hex')}`,
      guessA: publicInputs[0],
      guessB: publicInputs[1],
      guessC: publicInputs[2],
      guessD: publicInputs[3],
      hitCount: publicInputs[4],
      blowCount: publicInputs[5],
      publicSolutionHash: publicInputs[6],
      notes: {
        sourceProof: proofPath,
        sourcePublicInputs: publicInputsPath
      },
    };

    const outPath = resolveOutputPath('circuits/target/ethereum_inputs.json', 'target/ethereum_inputs.json');
    fs.writeFileSync(outPath, JSON.stringify(payload, null, 2) + '\n', 'utf8');

    console.log(`Wrote ${outPath}`);
  } catch (error) {
    console.error(error.message || error);
    process.exit(1);
  }
}

main();
