const { alice, bob, eve } = require("../scripts/sandbox/accounts");
const setup = require("./setup");

contract("Fiat to XTZ Payment System", () => {
  let storage,
    contract_address,
    contract_instance,
    oracle_address,
    oracle_instance,
    signerFactory,
    Tezos;

  before(async () => {
    const config = await setup();
    storage = config.storage;
    contract_address = config.contract_address;
    contract_instance = config.contract_instance;
    oracle_address = config.oracle_address;
    oracle_instance = config.oracle_instance;
    signerFactory = config.signerFactory;
    Tezos = config.Tezos;

    /*try {
      const op = await contract_instance.methods
        .update_oracle(oracle_address)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }*/
  });

  it("Alice should be the admin", () => {
    assert.equal(storage.admin, alice.pkh);
  });

  /*
   * ADMIN FEATURES
   */
  it("admin should be able to update transaction fee", async () => {
    signerFactory(bob.sk);

    let err = "";

    try {
      let op = await contract_instance.methods.update_tx_fee(5).send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    assert.equal(err, "NOT_AN_ADMIN");

    signerFactory(alice.sk);

    try {
      let op = await contract_instance.methods.update_tx_fee(1).send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    assert.equal(storage.tx_fee.toNumber(), 1);
  });

  it("admin should be able to update the oracle address", async () => {
    signerFactory(bob.sk);

    let err = "";

    try {
      let op = await contract_instance.methods
        .update_oracle(oracle_address)
        .send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    assert.equal(err, "NOT_AN_ADMIN");

    signerFactory(alice.sk);

    try {
      let op = await contract_instance.methods
        .update_oracle(oracle_address)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    assert.equal(storage.oracle, oracle_address);
  });

  /*
   * CLIENT FEATURES
   */
  it("should create a new empty client", async () => {
    assert.isUndefined(await storage.recipients.get(alice.pkh));

    const currency = "USD";

    try {
      const op = await contract_instance.methods.add_client(currency).send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    const client = await storage.recipients.get(alice.pkh);
    assert.equal(client[0], currency);
    assert.equal(client[1].size, 0);
  });

  it("should let clients add recipients", async () => {
    let recipient1 = { 0: alice.pkh, 1: 200 };
    let recipient2 = { 0: bob.pkh, 1: 344 };
    let recipient3 = { 0: eve.pkh, 1: 111 };

    // confirms Alice has no recipient yet
    let aliceRecipients = await storage.recipients.get(alice.pkh);
    assert.equal(aliceRecipients[1].size, 0);

    try {
      const op = await contract_instance.methods
        .add_recipients([recipient1, recipient2, recipient3])
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    // checks if recipients have been added
    aliceRecipients = await storage.recipients.get(alice.pkh);
    const newRecipients = [];
    aliceRecipients[1].forEach((v, k) =>
      newRecipients.push({
        address: k,
        value: v.toNumber()
      })
    );
    assert.lengthOf(newRecipients, 3);
    assert.lengthOf(
      newRecipients.filter(
        el => el.address === recipient1[0] && el.value === recipient1[1]
      ),
      1
    );
    assert.lengthOf(
      newRecipients.filter(
        el => el.address === recipient2[0] && el.value === recipient2[1]
      ),
      1
    );
    assert.lengthOf(
      newRecipients.filter(
        el => el.address === recipient3[0] && el.value === recipient3[1]
      ),
      1
    );
  });

  it("should allow a client to remove one of the recipients", async () => {
    const aliceRecipients = await storage.recipients.get(alice.pkh);
    let aliceIsRecipient = await aliceRecipients[1].get(alice.pkh);

    assert.isDefined(aliceIsRecipient);

    try {
      const op = await contract_instance.methods
        .remove_recipient(alice.pkh)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    const aliceNewRecipients = await storage.recipients.get(alice.pkh);

    assert.equal(aliceNewRecipients[1].size, aliceRecipients[1].size - 1);

    aliceIsRecipient = await aliceNewRecipients[1].get(alice.pkh);

    assert.isUndefined(aliceIsRecipient);
  });
});
