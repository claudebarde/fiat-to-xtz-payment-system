<script lang="ts">
  import { validateAddress } from "@taquito/utils";
  import store from "../store";

  let recipientAddress = "";
  let addressError = false;
  let recipientAmount = "";
  let amountError = false;
  let addRecipientError = false;
  let loadingAddRecipient = false;

  const addRecipient = async () => {
    addRecipientError = false;
    addressError = false;
    amountError = false;
    loadingAddRecipient = true;
    // wrong address format
    if (validateAddress(recipientAddress) !== 3) {
      addressError = true;
      loadingAddRecipient = false;
      return;
    }
    console.log(+recipientAmount);
    // wrong amount format
    if (isNaN(+recipientAmount) || +recipientAmount === 0) {
      amountError = true;
      loadingAddRecipient = false;
      return;
    }

    try {
      const op = await $store.contract.methods
        .add_recipients([[recipientAddress, recipientAmount]])
        .send();
      await op.confirmation();
      const newStorage = $store.contract.storage();
      store.updateContractStorage(newStorage);
      store.updateRecipients([
        { address: recipientAddress, amount: +recipientAmount },
        ...$store.userRecipients
      ]);
    } catch (error) {
      console.log(error);
      addRecipientError = true;
    } finally {
      loadingAddRecipient = false;
    }
  };
</script>

<style lang="scss">
  .add-recipient {
    text-align: center;
  }

  .new-recipient-details {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .error {
    color: red;
  }
</style>

<div class="add-recipient">
  {#if addRecipientError}
    <div><span style="color:red">An error has occurred</span></div>
  {:else}
    <div>Add a new recipient:</div>
  {/if}
  <div class="new-recipient-details">
    <div><span class:error={addressError}>Address:</span></div>
    <div>
      <input
        type="text"
        id="new-recipient-address"
        bind:value={recipientAddress}
        on:focus={() => (addressError = false)} />
    </div>
  </div>
  <div class="new-recipient-details">
    <div>
      <span class:error={amountError}>Amount in {$store.userCurrency}:</span>
    </div>
    <div>
      <input
        type="text"
        id="new-recipient-amount"
        bind:value={recipientAmount}
        on:focus={() => (amountError = false)} />
    </div>
  </div>
  <br />
  <button
    class={`button info small ${!recipientAmount && !recipientAddress ? 'disabled' : ''}`}
    class:loading={loadingAddRecipient}
    data-text={loadingAddRecipient ? 'Waiting' : 'Add'}
    disabled={loadingAddRecipient || !recipientAmount || !recipientAddress}
    on:click={addRecipient}>{loadingAddRecipient ? 'Waiting' : 'Add'}</button>
</div>
