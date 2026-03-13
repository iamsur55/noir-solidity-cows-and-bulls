import { Noir } from "@noir-lang/noir_js";
import { Barretenberg, UltraHonkBackend } from "@aztec/bb.js";
import initACVM from "@noir-lang/acvm_js";
import acvm from "@noir-lang/acvm_js/web/acvm_js_bg.wasm?url";
import noirc from "@noir-lang/noirc_abi/web/noirc_abi_wasm_bg.wasm?url";
import initNoirC from "@noir-lang/noirc_abi";
import circuit from './../public/cows_and_bulls.json';

await Promise.all([
  initACVM(fetch(acvm)),
  initNoirC(fetch(noirc))
]);

let noir: Noir;
let backend: UltraHonkBackend;

self.postMessage({ status: "worker_loaded" });

self.onmessage = async (event) => {

  const { type, input } = event.data;

  if (type === "init") {
    if (backend && noir) {
      return;
    }

    try {
      const barretenberg = await Barretenberg.new();
      backend = new UltraHonkBackend(circuit.bytecode, barretenberg);
      noir = new Noir(circuit);
      self.postMessage({ status: "worker_ready" });

    } catch (err) {
      console.error("Backend initialization failed:", err);
      self.postMessage({
        status: "error",
        error: String(err)
      });
    }
  }

  if (type === "prove") {

    if (!noir || !backend) {
      throw new Error("Worker not initialized");
    }
    try {
      const result = await noir.execute(input);
      const proofData = await backend.generateProof(result.witness, { verifierTarget: "evm" });

      self.postMessage({
        status: "proof_done",
        proof: proofData.proof,
        publicInputs: proofData.publicInputs,
      });

    } catch (err) {
      console.error("worker caught error: ", err);
      self.postMessage({
        status: "error",
        error: String(err)
      });
    }
  }
};
