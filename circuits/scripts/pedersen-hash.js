const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

function parseTomlLike(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const output = {};

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/);
    if (!match) continue;

    const key = match[1];
    let value = match[2].trim();

    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }

    output[key] = value;
  }

  return output;
}

function toInt(name, value) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`Invalid ${name}: ${value}`);
  }
  return parsed;
}

function readInputs(argv) {
  const defaultInputCandidates = ['Prover.toml', path.join('circuits', 'Prover.toml')];
  const fileFlagIndex = argv.indexOf('--file');
  if (fileFlagIndex >= 0) {
    const filePath = argv[fileFlagIndex + 1];
    if (!filePath) {
      throw new Error('Missing value for --file');
    }

    const resolved = path.resolve(process.cwd(), filePath);
    if (!fs.existsSync(resolved)) {
      throw new Error(`Input file not found: ${resolved}`);
    }

    const values = parseTomlLike(resolved);
    const salt = toInt('salt', values.salt);
    const solutionA = toInt('solutionA', values.solutionA);
    const solutionB = toInt('solutionB', values.solutionB);
    const solutionC = toInt('solutionC', values.solutionC);
    const solutionD = toInt('solutionD', values.solutionD);

    return { salt, solutionA, solutionB, solutionC, solutionD };
  }

  if (argv.length === 0) {
    const foundDefault = defaultInputCandidates
      .map((candidate) => path.resolve(process.cwd(), candidate))
      .find((candidatePath) => fs.existsSync(candidatePath));

    if (!foundDefault) {
      throw new Error(
        'No CLI args provided and no default Prover.toml found. Looked for Prover.toml and circuits/Prover.toml.'
      );
    }

    const values = parseTomlLike(foundDefault);
    const salt = toInt('salt', values.salt);
    const solutionA = toInt('solutionA', values.solutionA);
    const solutionB = toInt('solutionB', values.solutionB);
    const solutionC = toInt('solutionC', values.solutionC);
    const solutionD = toInt('solutionD', values.solutionD);

    return { salt, solutionA, solutionB, solutionC, solutionD };
  }

  if (argv.length !== 5) {
    throw new Error(
      'Usage: npm run hash -- <salt> <solutionA> <solutionB> <solutionC> <solutionD>\n   or: npm run hash -- --file Prover.toml\n   or: npm run hash (uses default Prover.toml)'
    );
  }

  return {
    salt: toInt('salt', argv[0]),
    solutionA: toInt('solutionA', argv[1]),
    solutionB: toInt('solutionB', argv[2]),
    solutionC: toInt('solutionC', argv[3]),
    solutionD: toInt('solutionD', argv[4]),
  };
}

function computeHashWithNargo({ salt, solutionA, solutionB, solutionC, solutionD }) {
  const helperDir = fs.mkdtempSync(path.join(os.tmpdir(), 'cows-and-bulls-hash-'));
  const helperSrcDir = path.join(helperDir, 'src');
  const proverBaseName = 'Prover';

  try {
    fs.mkdirSync(helperSrcDir, { recursive: true });

    fs.writeFileSync(
      path.join(helperDir, 'Nargo.toml'),
      [
        '[package]',
        'name = "hash_circuit"',
        'type = "bin"',
        'authors = [""]',
        'compiler_version = ">=0.1"',
        '',
        '[dependencies]',
        '',
      ].join('\n'),
      'utf8'
    );

    fs.writeFileSync(
      path.join(helperSrcDir, 'main.nr'),
      [
        'use dep::std;',
        '',
        'fn main(salt: u32, solutionA: u8, solutionB: u8, solutionC: u8, solutionD: u8) -> pub Field {',
        '    let solution_hash: Field = std::hash::pedersen_hash([',
        '        salt as Field,',
        '        solutionA as Field,',
        '        solutionB as Field,',
        '        solutionC as Field,',
        '        solutionD as Field,',
        '    ]);',
        '    print(solution_hash);',
        '    solution_hash',
        '}',
        '',
      ].join('\n'),
      'utf8'
    );

    fs.writeFileSync(
      path.join(helperDir, `${proverBaseName}.toml`),
      [
        `salt = "${salt}"`,
        `solutionA = "${solutionA}"`,
        `solutionB = "${solutionB}"`,
        `solutionC = "${solutionC}"`,
        `solutionD = "${solutionD}"`,
      ].join('\n') + '\n',
      'utf8'
    );

    const result = spawnSync('nargo', ['execute', '--package', 'hash_circuit', '--prover-name', proverBaseName], {
      cwd: helperDir,
      encoding: 'utf8',
    });

    if (result.status !== 0) {
      throw new Error(result.stderr || result.stdout || 'Failed to execute hash helper circuit.');
    }

    const output = `${result.stdout || ''}\n${result.stderr || ''}`;
    const match = output.match(/0x[0-9a-fA-F]+/);
    if (!match) {
      throw new Error('Hash was not found in nargo output.');
    }

    return match[0];
  } finally {
    fs.rmSync(helperDir, { recursive: true, force: true });
  }
}

function main() {
  try {
    const inputs = readInputs(process.argv.slice(2));
    const hash = computeHashWithNargo(inputs);
    console.log(hash);
  } catch (error) {
    console.error(error.message || error);
    process.exit(1);
  }
}

main();
