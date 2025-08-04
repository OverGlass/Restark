import { useAccount, useContract, useContractWrite } from '@starknet-react/core';
import React, { useCallback, useState } from 'react';

interface RestarkeButtonProps {
  contractAddress: string;
  className?: string;
}

const RESTARKE_ABI = [
  {
    name: "execute_auto_restake_self",
    type: "function",
    inputs: [],
    outputs: [
      {
        name: "amount",
        type: "core::integer::u256"
      }
    ],
    state_mutability: "external",
  }
];

export const RestarkeButton: React.FC<RestarkeButtonProps> = ({
  contractAddress,
  className = ""
}) => {
  const { account, address, status } = useAccount();
  const [isLoading, setIsLoading] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [lastRestakedAmount, setLastRestakedAmount] = useState<string | null>(null);

  const { contract } = useContract({
    abi: RESTARKE_ABI,
    address: contractAddress,
  });

  const calls = useMemo(() => {
    if (!contract || !address) return [];

    return contract.populateTransaction["execute_auto_restake_self"]();
  }, [contract, address]);

  const { writeAsync } = useContractWrite({
    calls,
  });

  const handleRestake = useCallback(async () => {
    if (!account || !contract) {
      setError("Please connect your wallet first");
      return;
    }

    setIsLoading(true);
    setError(null);
    setTxHash(null);

    try {
      // Execute the restake transaction
      const response = await writeAsync();

      if (response?.transaction_hash) {
        setTxHash(response.transaction_hash);

        // Wait for transaction to be accepted
        const receipt = await account.provider.waitForTransaction(
          response.transaction_hash
        );

        // Parse events to get the restaked amount
        if (receipt.events) {
          const restakedEvent = receipt.events.find(
            (event) => event.keys[0] === hash.getSelectorFromName("AutoRestakeExecuted")
          );

          if (restakedEvent && restakedEvent.data.length >= 3) {
            // The amount is at index 2 in the event data
            const amount = restakedEvent.data[2];
            setLastRestakedAmount(amount);
          }
        }

        setIsLoading(false);
      }
    } catch (err: any) {
      console.error("Restaking error:", err);
      setError(err.message || "Failed to restake rewards");
      setIsLoading(false);
    }
  }, [account, contract, writeAsync]);

  // Format the amount from wei to STARK (18 decimals)
  const formatAmount = (amount: string) => {
    try {
      const value = BigInt(amount);
      const stark = value / BigInt(10 ** 18);
      const remainder = value % BigInt(10 ** 18);
      const decimal = remainder.toString().padStart(18, '0').slice(0, 4);
      return `${stark}.${decimal} STARK`;
    } catch {
      return "0 STARK";
    }
  };

  // Determine button state and text
  const getButtonContent = () => {
    if (status === "disconnected") {
      return "Connect Wallet";
    }
    if (isLoading) {
      return (
        <span className="flex items-center justify-center">
          <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Restaking...
        </span>
      );
    }
    return "Restake Rewards";
  };

  const isDisabled = status === "disconnected" || isLoading;

  return (
    <div className="flex flex-col items-center space-y-4">
      <button
        onClick={handleRestake}
        disabled={isDisabled}
        className={`
          px-8 py-4 rounded-lg font-bold text-lg transition-all duration-200
          ${isDisabled
            ? 'bg-gray-400 cursor-not-allowed'
            : 'bg-blue-600 hover:bg-blue-700 active:scale-95'
          }
          text-white shadow-lg hover:shadow-xl
          ${className}
        `}
      >
        {getButtonContent()}
      </button>

      {/* Status Messages */}
      {error && (
        <div className="p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg">
          <p className="font-semibold">Error</p>
          <p className="text-sm">{error}</p>
        </div>
      )}

      {txHash && !error && (
        <div className="p-4 bg-green-100 border border-green-400 text-green-700 rounded-lg">
          <p className="font-semibold">Success!</p>
          <p className="text-sm">
            Transaction:
            <a
              href={`https://voyager.online/tx/${txHash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="ml-1 underline hover:text-green-800"
            >
              {txHash.slice(0, 8)}...{txHash.slice(-6)}
            </a>
          </p>
          {lastRestakedAmount && (
            <p className="text-sm mt-1">
              Restaked: {formatAmount(lastRestakedAmount)}
            </p>
          )}
        </div>
      )}

      {/* Wallet Status */}
      {address && (
        <div className="text-sm text-gray-600">
          Connected: {address.slice(0, 6)}...{address.slice(-4)}
        </div>
      )}
    </div>
  );
};

// Usage example in your app:
// <RestarkeButton contractAddress="0x..." />
