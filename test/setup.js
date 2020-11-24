const CONTRACT = artifacts.require("PaymentSystem");
const ORACLE = artifacts.require("FakeOracle");
const { TezosToolkit } = require("@taquito/taquito");
const { InMemorySigner } = require("@taquito/signer");
const { alice } = require("../scripts/sandbox/accounts");

let storage,
  contract_address,
  contract_instance,
  oracle_address,
  oracle_instance;

let Tezos = new TezosToolkit("http://localhost:8732");

const signerFactory = async pk => {
  await Tezos.setProvider({ signer: new InMemorySigner(pk) });
  return Tezos;
};

module.exports = async () => {
  contract_instance = await CONTRACT.deployed();
  // this code bypasses Truffle config to be able to have different signers
  // until I find how to do it directly with Truffle
  await Tezos.setProvider({ rpc: "http://localhost:8732" });
  await signerFactory(alice.sk);
  /**
   * Display the current contract address for debugging purposes
   */
  console.log("Contract deployed at:", contract_instance.address);
  contract_address = contract_instance.address;
  contract_instance = await Tezos.contract.at(contract_instance.address);
  storage = await contract_instance.storage();

  // deploys the exchange contract
  oracle_instance = await ORACLE.deployed();
  console.log("Oracle deployed at:", oracle_instance.address);
  oracle_address = oracle_instance.address;
  oracle_instance = await Tezos.contract.at(oracle_instance.address);

  return {
    storage,
    contract_address,
    contract_instance,
    oracle_address,
    oracle_instance,
    signerFactory,
    Tezos
  };
};
