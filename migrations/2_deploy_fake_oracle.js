const { MichelsonMap } = require("@taquito/taquito");

const FakeOracle = artifacts.require("FakeOracle");

const initialStorage = MichelsonMap.fromLiteral({
  "XTZ-USD": {
    0: Math.round(Date.now() / 1000).toString(),
    1: "2698757"
  }
});

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(FakeOracle, initialStorage);
};
