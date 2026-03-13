import { useState, useRef, useEffect } from "react";
import { parseAbi, isAddress, padHex, toHex, type Address } from "viem";
import { useConnect, useWriteContract, useReadContract } from "wagmi";
import { injected } from '@wagmi/connectors';
import deployment from "../../broadcast/CowsAndBulls.s.sol/31337/run-latest.json";

const CONTRACT_ADDRESS: Address = deployment.transactions.find(
  (tx: any) => tx.contractName === "CowsAndBulls"
)!.contractAddress as Address;

const ABI = parseAbi([
  "function createNewGame(address breaker) public",
  "function makeGuess(address maker, bytes32 guessA, bytes32 guessB, bytes32 guessC, bytes32 guessD) public",
  "function giveFeedback(address breaker, bytes proof, bytes32 cows, bytes32 bulls, bytes32 publicSolutionHash) public",
  "function games(address maker, address breaker) external view returns (uint8,uint8,uint8,bool,bytes32,bytes32,bytes32,bytes32)"
,
]);

const toBytes32 = (value: string) =>
  padHex(`0x${BigInt(value).toString(16)}`, { size: 32 });


export default function GamePage() {

  const connect = useConnect();
  const { mutateAsync } = useWriteContract();

  const [maker, setMaker] = useState("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"); // anvil #0
  const [breaker, setBreaker] = useState("0x70997970C51812dc3A010C7d01b50e0d17dc79C8"); // anvil #1
  const [guess, setGuess] = useState("");
  const [loading, setLoading] = useState(false);
  const shouldFetch = isAddress(maker) && isAddress(breaker);
  const workerReadyRef = useRef(false);
  const workerRef = useRef<Worker>(null);

  // Feedback inputs (maker's private knowledge)
  const [cows, setCows] = useState("");
  const [bulls, setBulls] = useState("");
  const [publicSolutionHash, setPublicSolutionHash] = useState("");
  const [solutionA, setSolutionA] = useState("");
  const [solutionB, setSolutionB] = useState("");
  const [solutionC, setSolutionC] = useState("");
  const [solutionD, setSolutionD] = useState("");
  const [salt, setSalt] = useState("");

  useEffect(() => {
    const worker = new Worker(
      new URL("./proofWorker.ts", import.meta.url),
      { type: "module" }
    );

    workerRef.current = worker;

    worker.onmessage = (event) => {
      const { status } = event.data;

      if (status === "worker_loaded") {
        worker.postMessage({ type: "init" });
      }

      if (status === "worker_ready") {
        workerReadyRef.current = true;
      }
    };

    worker.postMessage({ type: "init" });

    const errorHandler = (event: ErrorEvent) => {
      console.error("Uncaught error:", event.error);
    };
    window.addEventListener("error", errorHandler);

    return () => {
      worker.terminate();
      window.removeEventListener("error", errorHandler);
    };

  }, []);

  // -------- Create Game --------
  const createGame = async () => {
    if (!isAddress(breaker)) {
        alert("Invalid address");
    return;
}
    await mutateAsync({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: "createNewGame",
      args: [breaker as Address],
    });
  };

  // -------- Make Guess --------
  const makeGuess = async () => {
    const digits = guess.split("").map(toBytes32);
    await mutateAsync({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: "makeGuess",
      args: [
        maker as Address,
        digits[0],
        digits[1],
        digits[2],
        digits[3],
      ],
    });
  };

  const giveFeedback = async () => {
    setLoading(true);

    workerRef.current?.postMessage({
      type: "prove",
      input: {
        guessA: Number(gameState[4].substring(gameState[4].length-1,gameState[4].length)),
        guessB: Number(gameState[5].substring(gameState[5].length-1,gameState[5].length)),
        guessC: Number(gameState[6].substring(gameState[6].length-1,gameState[6].length)),
        guessD: Number(gameState[7].substring(gameState[7].length-1,gameState[7].length)),
        cows: Number(cows),
        bulls: Number(bulls),
        publicSolutionHash,
        solutionA: Number(solutionA),
        solutionB: Number(solutionB),
        solutionC: Number(solutionC),
        solutionD: Number(solutionD),
        salt: Number(salt),
      }
    });

    workerRef.current!.onmessage = async (event) => {
      const { status, proof, publicInputs, error } = event.data;

      if (status === "proof_done") {
        try {
          const cowsHex = typeof publicInputs[4] === 'bigint'
            ? padHex(`0x${publicInputs[4].toString(16)}`, { size: 32 })
            : padHex(`0x${BigInt(publicInputs[4]).toString(16)}`, { size: 32 });

          const bullsHex = typeof publicInputs[5] === 'bigint'
            ? padHex(`0x${publicInputs[5].toString(16)}`, { size: 32 })
            : padHex(`0x${BigInt(publicInputs[5]).toString(16)}`, { size: 32 });

          const solutionHashHex = typeof publicInputs[6] === 'bigint'
            ? padHex(`0x${publicInputs[6].toString(16)}`, { size: 32 })
            : padHex(`0x${BigInt(publicInputs[6]).toString(16)}`, { size: 32 });

          const proofHex = `0x${Array.from(proof).map(b => b.toString(16).padStart(2, '0')).join('')}`;

          await mutateAsync({
            address: CONTRACT_ADDRESS,
            abi: ABI,
            functionName: "giveFeedback",
            args: [
              breaker as Address,
              proofHex as `0x${string}`,
              cowsHex as `0x${string}`,
              bullsHex as `0x${string}`,
              solutionHashHex as `0x${string}`
            ],
          });

          await refetchGameState();
          setLoading(false);
        } catch (err: any) {
          console.error("Contract call error:", err.message || err.reason || err.toString());
          setLoading(false);
        }
      } else if (status === "error") {
        console.error("Proof generation error:", error);
        setLoading(false);
      }
    };
  };

  // -------- Get Game State--------
  const { data: gameState, refetch: refetchGameState, isLoading, error } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: "games",
    args: shouldFetch ? [maker as Address, breaker as Address] : undefined,
    query: { enabled: shouldFetch },
  }) as { data?: readonly [number, number, number, boolean, `0x${string}`, `0x${string}`, `0x${string}`, `0x${string}`], refetch: () => void, isLoading: boolean, error: any };

  return (
    <div>
      <h2>ZK Cows & Bulls</h2>
      <button onClick={() => connect.mutate({ connector: injected() })}>
      Connect
    </button>
      <div>Breaker:</div>
      <input
        placeholder="Breaker address"
        value={breaker}
        onChange={(e) => setBreaker(e.target.value)}
      />
      <br /><br />
      <div>Maker:</div>
      <input
        placeholder="Maker address"
        value={maker}
        onChange={(e) => setMaker(e.target.value)}
      />
      <br /><br />
      <div>Guess:</div>
      <input
        placeholder="4-digit guess"
        value={guess}
        onChange={(e) => setGuess(e.target.value)}
      />
      <br /><br />
      <div>Feedback inputs (maker only):</div>
      <input placeholder="Cows" value={cows} onChange={(e) => setCows(e.target.value)} />
      <input placeholder="Bulls" value={bulls} onChange={(e) => setBulls(e.target.value)} />
      <input placeholder="Public solution hash" value={publicSolutionHash} onChange={(e) => setPublicSolutionHash(e.target.value)} style={{width: "420px"}} />
      <br />
      <input placeholder="Solution A" value={solutionA} onChange={(e) => setSolutionA(e.target.value)} />
      <input placeholder="Solution B" value={solutionB} onChange={(e) => setSolutionB(e.target.value)} />
      <input placeholder="Solution C" value={solutionC} onChange={(e) => setSolutionC(e.target.value)} />
      <input placeholder="Solution D" value={solutionD} onChange={(e) => setSolutionD(e.target.value)} />
      <input placeholder="Salt" value={salt} onChange={(e) => setSalt(e.target.value)} />
      <br /><br />
      <div>Interaction: </div>
      <button onClick={createGame} disabled={loading}>Create Game</button>
      <button onClick={makeGuess} disabled={loading}>Make Guess</button>
      <button onClick={giveFeedback} disabled={loading}>Give Feedback</button>
      {loading && <p>⏳ Loading...</p>}
      <br /><br />
      <div>
        <div>Game state:</div>
        {error ? (
          <p style={{color: 'red'}}>No game exists yet. Click "Create Game" to start.</p>
        ) : isLoading ? (
          <p>Loading...</p>
        ) : gameState ? (
          <>
            <p>Round: {gameState[0]?.toString()}</p>
            <p>Cows: {(gameState as unknown as any[])?.[1]?.toString()}</p>
            <p>Bulls: {(gameState as unknown as any[])?.[2]?.toString()}</p>
            <p>Breaker Turn: {(gameState as unknown as any[])?.[3]?.toString()}</p>
            <p>A: {(gameState as unknown as any[])?.[4]?.toString()}</p>
            <p>B: {(gameState as unknown as any[])?.[5]?.toString()}</p>
            <p>C: {(gameState as unknown as any[])?.[6]?.toString()}</p>
            <p>D: {(gameState as unknown as any[])?.[7]?.toString()}</p>
          </>
        ) : (
          <p>No data</p>
        )}

     </div>

    </div>


  );
}
