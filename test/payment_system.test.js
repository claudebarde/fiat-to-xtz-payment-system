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

  let fetchRecipientsBalances = async (pkh, storage) => {
    const balancePromises = [];
    const recipients = [];
    const recipientsFiat = {};
    const recipientsBalances = {};
    const userRecipients = await storage.recipients.get(pkh);
    let totalAmountInFiat = 0;
    userRecipients[1].forEach(async (v, k) => {
      // updates the total amount to be sent
      totalAmountInFiat += v.toNumber();
      // records recipients amounts in fiat
      recipientsFiat[k] = v.toNumber();
      // records initial balances for these accounts
      balancePromises.push(Tezos.tz.getBalance(k));
      recipients.push(k);
    });
    const resolvedBalancePromises = await Promise.all(balancePromises);
    recipients.forEach((r, i) => {
      recipientsBalances[r] = resolvedBalancePromises[i].toNumber();
    });

    return { totalAmountInFiat, recipientsBalances, recipientsFiat };
  };

  before(async () => {
    const config = await setup();
    storage = config.storage;
    contract_address = config.contract_address;
    contract_instance = config.contract_instance;
    oracle_address = config.oracle_address;
    oracle_instance = config.oracle_instance;
    signerFactory = config.signerFactory;
    Tezos = config.Tezos;
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
    let fee = 1;

    try {
      let op = await contract_instance.methods
        .update_tx_fee(fee * 10 ** 6)
        .send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    assert.equal(err, "NOT_AN_ADMIN");

    signerFactory(alice.sk);

    try {
      let op = await contract_instance.methods
        .update_tx_fee(fee * 10 ** 6)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    assert.equal(storage.tx_fee.toNumber(), fee * 10 ** 6);
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
    let recipient1 = { 0: alice.pkh, 1: 2 };
    let recipient2 = { 0: bob.pkh, 1: 3 };
    let recipient3 = { 0: eve.pkh, 1: 4 };

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

    storage = await contract_instance.storage();

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
    let bobIsRecipient = await aliceRecipients[1].get(bob.pkh);

    assert.isDefined(bobIsRecipient);

    try {
      const op = await contract_instance.methods
        .remove_recipient(bob.pkh)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    const aliceNewRecipients = await storage.recipients.get(alice.pkh);

    assert.equal(aliceNewRecipients[1].size, aliceRecipients[1].size - 1);

    bobIsRecipient = await aliceNewRecipients[1].get(bob.pkh);

    assert.isUndefined(bobIsRecipient);
  });

  it("should allow a client to update the amount of one of the recipients", async () => {
    const aliceRecipients = await storage.recipients.get(alice.pkh);
    const eveAmount = await aliceRecipients[1].get(eve.pkh);
    const eveNewAmount = eveAmount.toNumber() + 2;

    try {
      const op = await contract_instance.methods
        .update_recipient(eve.pkh, eveNewAmount)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    const aliceUpdatedRecipients = await storage.recipients.get(alice.pkh);
    const eveUpdatedAmount = await aliceUpdatedRecipients[1].get(eve.pkh);

    assert.equal(eveUpdatedAmount, eveNewAmount);
  });

  it("should allow clients to update their own address", async () => {
    try {
      const op = await contract_instance.methods.update_client(bob.pkh).send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }
    // Alice shouldn't be registered as a client anymore
    storage = await contract_instance.storage();

    const isAliceClient = await storage.recipients.get(alice.pkh);
    assert.isUndefined(isAliceClient);
  });

  it("should allow Bob to send a payment", async () => {
    signerFactory(bob.sk);

    let err = "";
    const bobInitialBalance = await Tezos.tz.getBalance(bob.pkh);
    const {
      totalAmountInFiat,
      recipientsBalances: bobRecipientsInitialBalances
    } = await fetchRecipientsBalances(bob.pkh, storage);
    const bobRecipients = await storage.recipients.get(bob.pkh);
    //console.log("total amount in fiat:", totalAmountInFiat);
    //console.log(bobRecipientsInitialBalances);

    try {
      const op = await contract_instance.methods
        .request_payment([["unit"]])
        .send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    // should fail because no funds where sent
    assert.equal(err, "NO_AMOUNT");

    // estimates total amount
    const oracleStorage = await oracle_instance.storage();
    const currency_pair = await oracleStorage.get(`XTZ-${bobRecipients[0]}`);
    const totalAmountInXtz =
      currency_pair[1] * totalAmountInFiat + storage.tx_fee.toNumber();

    // console.log("total amount in xtz:", totalAmountInXtz);

    try {
      const op = await contract_instance.methods
        .request_payment([["unit"]])
        .send({ amount: totalAmountInXtz, mutez: true });
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await contract_instance.storage();

    const bobNewBalance = await Tezos.tz.getBalance(bob.pkh);
    const {
      recipientsBalances: bobRecipientsNewBalances,
      recipientsFiat
    } = await fetchRecipientsBalances(bob.pkh, storage);

    // console.log(bobInitialBalance.toNumber(), bobNewBalance.toNumber());
    // console.log(bobRecipientsInitialBalances, bobRecipientsNewBalances);

    assert.isBelow(
      bobNewBalance.toNumber(),
      bobInitialBalance.toNumber() - totalAmountInXtz
    );
    assert.equal(
      bobRecipientsInitialBalances.length,
      bobRecipientsNewBalances.length
    );

    const bobRecipientsAddresses = Object.keys(bobRecipientsNewBalances);

    for (let i = 0; i < bobRecipientsAddresses.length; i++) {
      const expectedSentXtz =
        recipientsFiat[bobRecipientsAddresses[i]] * currency_pair[1];
      // console.log(`expected XTZ: ${expectedSentXtz} to ${bobRecipientsAddresses[i]}`);
      assert.equal(
        bobRecipientsNewBalances[bobRecipientsAddresses[i]],
        bobRecipientsInitialBalances[bobRecipientsAddresses[i]] +
          expectedSentXtz
      );
    }

    assert.isFalse(storage.paused);
  });
});
