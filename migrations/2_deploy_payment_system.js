const { MichelsonMap } = require("@taquito/taquito");
const { alice } = require("../scripts/sandbox/accounts");

const PaymentSystem = artifacts.require("PaymentSystem");

const initialStorage = {
  recipients: new MichelsonMap(),
  pending_payments: new MichelsonMap(),
  tx_fee: 0,
  admin: alice.pkh,
  oracle: alice.pkh
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(PaymentSystem, initialStorage);
};
