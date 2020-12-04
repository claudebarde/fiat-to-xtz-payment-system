const { MichelsonMap } = require("@taquito/taquito");
const { alice } = require("../scripts/sandbox/accounts");

const PaymentSystem = artifacts.require("PaymentSystem");

const initialStorage = {
  recipients: new MichelsonMap(),
  pending_payment: null,
  tx_fee: 0,
  admin: alice.pkh,
  oracle: alice.pkh,
  paused: false
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(PaymentSystem, initialStorage);
};
