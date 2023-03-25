import '@/styles/globals.css'
import type { AppProps } from 'next/app'
import { WagmiConfig, createClient, configureChains, goerli, mainnet,  } from 'wagmi'
import { jsonRpcProvider } from 'wagmi/providers/jsonRpc'

const { chains, provider, webSocketProvider } = configureChains(
  [goerli, mainnet],
  [jsonRpcProvider({
    rpc: (chain) => ({
      http: `http://127.0.0.1:7545`,
    }),
  })],
)

const client = createClient({
  autoConnect: true,
  provider,
  webSocketProvider,
})

export default function App({ Component, pageProps }: AppProps) {
  return (
    <WagmiConfig client={client}>
      <Component {...pageProps} />
    </WagmiConfig>
  )
}
