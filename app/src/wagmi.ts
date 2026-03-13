import { createConfig, http } from "wagmi";
import { localhost } from "wagmi/chains";

export const config = createConfig({
  chains: [localhost],
  transports: {
    [localhost.id]: http(),
  },
});