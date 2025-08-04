import { mainnet, sepolia } from '@starknet-react/chains';
import { InjectedConnector, StarknetConfig, publicProvider } from '@starknet-react/core';
import { RestarkeButton } from './RestarkeButton';

// Configure connectors
const connectors = [
  new InjectedConnector({ options: { id: 'braavos' }}),
  new InjectedConnector({ options: { id: 'argentX' }}),
];

// Replace with your deployed Restarke contract address
const RESTARKE_CONTRACT_ADDRESS = "0x..."; // TODO: Add your contract address

function App() {
  return (
    <StarknetConfig
      chains={[mainnet, sepolia]}
      provider={publicProvider()}
      connectors={connectors}
    >
      <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white">
        {/* Header */}
        <header className="border-b border-gray-700">
          <div className="container mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
                  Restarke
                </h1>
                <span className="text-sm text-gray-400">
                  Compound your Starknet staking rewards
                </span>
              </div>
              <starknet-connect />
            </div>
          </div>
        </header>

        {/* Main Content */}
        <main className="container mx-auto px-4 py-16">
          <div className="max-w-2xl mx-auto">
            {/* Hero Section */}
            <div className="text-center mb-12">
              <h2 className="text-5xl font-bold mb-4">
                Maximize Your Staking Returns
              </h2>
              <p className="text-xl text-gray-400 mb-8">
                Claim and restake your STARK rewards in one click.
                No fees. No hassle. Just compound growth.
              </p>
            </div>

            {/* Stats Card */}
            <div className="bg-gray-800 rounded-xl p-8 mb-12 shadow-2xl">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div className="text-center">
                  <p className="text-gray-400 text-sm mb-1">APY Boost</p>
                  <p className="text-2xl font-bold text-green-400">+15%</p>
                </div>
                <div className="text-center">
                  <p className="text-gray-400 text-sm mb-1">Time Saved</p>
                  <p className="text-2xl font-bold text-blue-400">100%</p>
                </div>
                <div className="text-center">
                  <p className="text-gray-400 text-sm mb-1">Service Fee</p>
                  <p className="text-2xl font-bold text-purple-400">0%</p>
                </div>
              </div>

              {/* Restake Button */}
              <div className="flex justify-center">
                <RestarkeButton contractAddress={RESTARKE_CONTRACT_ADDRESS} />
              </div>
            </div>

            {/* How It Works */}
            <div className="bg-gray-800 rounded-xl p-8 shadow-2xl">
              <h3 className="text-2xl font-bold mb-6">How It Works</h3>
              <div className="space-y-4">
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0 w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center font-bold">
                    1
                  </div>
                  <div>
                    <h4 className="font-semibold mb-1">Connect Your Wallet</h4>
                    <p className="text-gray-400">
                      Use Braavos or ArgentX to connect your staker account
                    </p>
                  </div>
                </div>
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0 w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center font-bold">
                    2
                  </div>
                  <div>
                    <h4 className="font-semibold mb-1">Click Restake</h4>
                    <p className="text-gray-400">
                      One click to claim and restake all your pending rewards
                    </p>
                  </div>
                </div>
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0 w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center font-bold">
                    3
                  </div>
                  <div>
                    <h4 className="font-semibold mb-1">Watch It Grow</h4>
                    <p className="text-gray-400">
                      Your rewards are automatically compounded for maximum returns
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* FAQ Section */}
            <div className="mt-12 text-center">
              <h3 className="text-xl font-semibold mb-4">Frequently Asked Questions</h3>
              <div className="space-y-4 text-left max-w-xl mx-auto">
                <details className="bg-gray-800 rounded-lg p-4">
                  <summary className="cursor-pointer font-semibold">Is it safe?</summary>
                  <p className="mt-2 text-gray-400">
                    Yes! The contract is permissionless and never holds your funds.
                    It only executes the claim and restake operations in a single transaction.
                  </p>
                </details>
                <details className="bg-gray-800 rounded-lg p-4">
                  <summary className="cursor-pointer font-semibold">What are the fees?</summary>
                  <p className="mt-2 text-gray-400">
                    There are no fees! Restarke is a public good for the Starknet community.
                  </p>
                </details>
                <details className="bg-gray-800 rounded-lg p-4">
                  <summary className="cursor-pointer font-semibold">How often should I restake?</summary>
                  <p className="mt-2 text-gray-400">
                    We recommend restaking weekly or monthly, depending on your stake size.
                    Larger stakes benefit from more frequent compounding.
                  </p>
                </details>
              </div>
            </div>
          </div>
        </main>

        {/* Footer */}
        <footer className="border-t border-gray-700 mt-20">
          <div className="container mx-auto px-4 py-8">
            <div className="flex flex-col md:flex-row items-center justify-between">
              <div className="mb-4 md:mb-0">
                <p className="text-gray-400">
                  Built with ❤️ for the Starknet community
                </p>
              </div>
              <div className="flex space-x-6">
                <a
                  href="https://github.com/yourusername/restarke"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  GitHub
                </a>
                <a
                  href="https://voyager.online/contract/YOUR_CONTRACT_ADDRESS"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  Contract
                </a>
                <a
                  href="https://twitter.com/yourusername"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  Twitter
                </a>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </StarknetConfig>
  );
}

export default App;
