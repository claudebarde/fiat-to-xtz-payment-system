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

/*const initialStorage = {
  recipients: new MichelsonMap(),
  pending_payment: null,
  tx_fee: 0,
  admin: "tz1Me1MGhK7taay748h4gPnX2cXvbgL6xsYL",
  oracle: "KT1AdbYiPYb5hDuEuVrfxmFehtnBCXv4Np7r",
  paused: false
};*/

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(PaymentSystem, initialStorage);
};
