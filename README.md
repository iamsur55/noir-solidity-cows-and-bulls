# Noir Solidity Cows and Bulls

An educational project demonstrating zero-knowledge proofs on Ethereum through a game of [Cows and Bulls](https://en.wikipedia.org/wiki/Bulls_and_cows), where a smart contract verifies that the results of a round are valid without revealing secret information.

This repository combines a Noir circuit, Barretenberg proof generation, and Foundry smart contracts to run a Cows and Bulls game on Ethereum.

At a high level, the flow is:

1. define the inputs of the circuit
2. execute the circuit and generate proof artifacts
3. generate a Solidity verifier
4. verify the proof through the on-chain contract

## Acknowledgement
Inspiration was taken [Vezenovm](https://github.com/vezenovm/mastermind-noir/tree/master)

## Structure

- `circuits/`: Nargo circuit package and proving artifacts.
  - `src/main.nr`: Cows and Bulls constraint system.
  - `Nargo.toml`, `Prover.toml`, `Prover.example.toml`: circuit config and prover inputs.
  - `scripts/`: helper scripts for Pedersen hashing and Ethereum input export.
  - `target/`: generated files (witness/proof/public inputs/verifier/verification)
- `src/`: Solidity application contract (`CowsAndBulls.sol`) that verifies zk proofs.
- `test/`: Foundry tests
- `script/`: Foundry broadcast scripts for deployment and interaction
- `.github/workflows/test.yml`: CI pipeline (installs pinned Foundry/Noir/BB, generates zk artifacts, runs fmt/build/tests).

## Setup
### Nargo
This project uses Nargo. It is assumed that the user has access to the `nargo CLI tool`. If not, get yours with

```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
noirup -v 1.0.0-beta.18
```

If `noirup` does not work, source your `.bashrc` / `.zshrc`

```bash
source ~/.bashrc || source ~/.zshrc
```

verify: `nargo --version`

### Barretenberg
This project uses Barretenberg. It is assumed that the user has access to the `barretenberg CLI tool`. If not, get your with

```bash
curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/next/barretenberg/bbup/install | bash
bbup -v 3.0.0-nightly.20260102
```

If `bbup` does not work, source your `.bashrc` / `.zshrc`

```bash
source ~/.bashrc || source ~/.zshrc
```

verify: `bb --version`

### Foundry
This project uses Foundry. It is assumed that the user has access to `foundry`. If not, please run

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup --install 1.5.1-stable
```

If `foundryup` does not work, source your `.bashrc` / `.zshrc`

```bash
source ~/.bashrc || source ~/.zshrc
```

verify: `forge --version`

## Commands
These commands are the standard workflow for building artifacts and interacting with the project.

### Check circuit
Validates the circuit and creates/overwrites `circuits/Prover.toml` with default structure and empty values. Unless for development purposes, the rest of this repo uses the configuration as found in `Game.toml.example`

```bash
npm run zk:check
```

### Compute Pedersen hash

```bash
npm run tool:hash
```
The `stdout` should contain something like: `PublicSolutionHash: 0x17df526bf4b433952da1be4573e3be254cdd8d695aff821e75f86c833a592954` and potentially some errors, but you may ignore them. Paste the `publicSolutionHash` in your file `Game.toml`.

### Execute circuit (witness generation)
Runs `src/main.nr` with values from `Game.toml` and writes witness `target/cows_and_bulls.gz`.

```bash
npm run zk:execute
```

### Generate Solidity verifier
Produces verifier artifacts and writes `circuits/target/Verifier.sol`.

```bash
npm run zk:verifier
```

### Generate zk proof
Produces proof artifacts in `circuits/target/proof` and `circuits/target/public_inputs`.

```bash
npm run zk:proof
```

### Run Solidity tests
Requires `circuits/target/proof` and `circuits/target/public_inputs` (from `npm run zk:proof`).

```bash
npm run foundry:test
```

### Start local Anvil node
```bash
npm run foundry:anvil
```

### Deploy to local Anvil
```bash
npm run foundry:deploy_local
```

### Send `createNewGame` transaction
Requires a deployed `CowsAndBulls` instance and `MAKER_PRIVATE_KEY` set in `.env`. The `MAKER_PRIVATE_KEY` should correspond to the `makerAddress` address in `Game.toml`.

```bash
npm run foundry:newGame
```

### Send `makeGuess` transaction
Requires a deployed `CowsAndBulls` instance and `BREAKER_PRIVATE_KEY` set in `.env`. The `BREAKER_PRIVATE_KEY` should correspond to the `breakerAddress` address in `Game.toml`.

```bash
npm run foundry:makeGuess
```

### Send `giveFeedback` transaction
Requires a deployed `CowsAndBulls` instance and `circuits/target/proof` and `circuits/target/public_inputs` (from `npm run zk:proof`). The `MAKER_PRIVATE_KEY` set in `.env` should correspond to the `makerAddress` address in `Game.toml`.

```bash
npm run foundry:giveFeedback
```

### Export Ethereum-ready inputs
Converts proof/public inputs to a human-readable Ethereum input format.

```bash
npm run tool:export-eth-inputs
```

## CI Integration

GitHub Actions runs the `check` job from `.github/workflows/test.yml` with the following tool versions:

- Foundry `1.5.1-stable`
- Nargo `1.0.0-beta.18`
- Barretenberg `3.0.0-nightly.20260102`

The CI chain is executed through the same npm scripts used locally:

1. `npm run zk:check`
2. `cp circuits/Prover.example.toml circuits/Prover.toml`
3. `npm run zk:execute`
4. `npm run zk:verifier`
5. `npm run zk:proof`
6. `forge fmt --check`
7. `forge build --sizes`
8. `npm run foundry:test`

`Verifier.sol`, `proof`, and `public_inputs` are generated in `circuits/target` during CI and are intentionally gitignored.