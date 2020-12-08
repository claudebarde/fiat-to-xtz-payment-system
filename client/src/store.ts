import { writable } from "svelte/store";
import {
  TezosToolkit,
  ContractAbstraction,
  Wallet,
  ContractProvider
} from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";

interface State {
  Tezos: TezosToolkit;
  wallet: BeaconWallet;
  userAddress: string | undefined;
  network: "mainnet" | "testnet" | "local";
  contractAddress: { mainnet: string; testnet: string; local: string };
  rpcUrl: { mainnet: string; testnet: string; local: string };
  contractStorage: any;
  contract: ContractAbstraction<ContractProvider> | undefined;
}

const initialState: State = {
  Tezos: undefined,
  wallet: undefined,
  userAddress: undefined,
  network: "testnet",
  contractAddress: {
    mainnet: "",
    testnet: "KT1WoCE1tiSj668Cgz3qhxG318Lp65HvnxgW",
    local: "KT1N1JE5vEUZGDHfPjeBHpYLeaAJhGUWfWQV"
  },
  rpcUrl: {
    mainnet: "",
    testnet: "https://delphinet-tezos.giganode.io",
    local: "http://localhost:8732"
  },
  contractStorage: undefined,
  contract: undefined
};

const store = writable(initialState);

const state = {
  subscribe: store.subscribe,
  updateTezos: (tezos: TezosToolkit) =>
    store.update(store => ({ ...store, Tezos: tezos })),
  updateWallet: (wallet: BeaconWallet) =>
    store.update(store => ({ ...store, wallet })),
  updateUserAddress: (address: string) => {
    store.update(store => ({ ...store, userAddress: address }));
  },
  updateContract: (instance: ContractAbstraction<ContractProvider>) => {
    store.update(store => ({ ...store, contract: instance }));
  },
  updateContractStorage: (storage: any) => {
    store.update(store => ({ ...store, contractStorage: storage }));
  }
};

export default state;
