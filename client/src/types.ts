import { TezosToolkit, ContractAbstraction, Wallet } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";

export interface Payment {
  opHash: string;
  totalAmount: number;
  dispatchedAmounts: { amount: number; to: string }[];
  timestamp: number;
  date: Date;
  fee: number;
  exchangeRate: { pair: string; timestamp: number; rate: number } | null;
  fiat: string;
}

export interface State {
  Tezos: TezosToolkit;
  wallet: BeaconWallet;
  userAddress: string | undefined;
  userCurrency: string | undefined;
  userRecipients: { address: string; amount: number }[] | null;
  network: "mainnet" | "testnet" | "local";
  contractAddress: { mainnet: string; testnet: string; local: string };
  oracleAddress: { mainnet: string; testnet: string; local: string };
  rpcUrl: { mainnet: string; testnet: string; local: string };
  contractStorage: any;
  contract: ContractAbstraction<Wallet> | undefined;
  payments: Payment[];
  fullPaymentsHistory: boolean;
}
