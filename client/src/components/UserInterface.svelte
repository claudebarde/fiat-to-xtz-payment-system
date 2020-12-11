<script lang="ts">
  import { fly } from "svelte/transition";
  import store from "../store";
  import AddRecipient from "./AddRecipient.svelte";
  import Recipients from "./Recipients.svelte";

  let selectedCurrency = "";
  let selectedCurrencyError = false;
  let loadingCreateAccount = false;
  let createAccountError = false;
  let opHash = "";

  const createAccount = async () => {
    createAccountError = false;
    if (!selectedCurrency) {
      selectedCurrencyError = true;
    } else {
      selectedCurrencyError = false;
      loadingCreateAccount = true;
      // confirms creation of new client account
      try {
        const op = await $store.contract.methods
          .add_client(selectedCurrency)
          .send();
        opHash = op.opHash;
        await op.confirmation();
        const newStorage = $store.contract.storage();
        store.updateContractStorage(newStorage);
        store.updateRecipients([]);
      } catch (error) {
        console.log(error);
        createAccountError = true;
      } finally {
        loadingCreateAccount = false;
      }
    }
  };
</script>

<style lang="scss">
  .currencies {
    display: flex;
    justify-content: center;
    align-items: center;

    div {
      margin: 5px 20px;
      cursor: pointer;
    }

    label {
      cursor: pointer;
      border: solid 2px transparent;
      padding: 3px 5px;
      margin: 5px 10px;

      &#selected {
        border: solid 2px #0380b3;
      }
    }

    input[type="radio"] {
      display: none;
    }
  }
</style>

<div class="container" in:fly={{ x: -1000, duration: 2500, delay: 1000 }}>
  {#if $store.userRecipients === null}
    <h3>Create a new account</h3>
    <div class="currencies">
      <span style={selectedCurrencyError ? 'color:red' : ''}>Currency:</span>
      <label
        for="currency-USD"
        id={selectedCurrency === 'USD' ? 'selected' : ''}><input
          type="radio"
          name="currency"
          id="currency-USD"
          value="USD"
          bind:group={selectedCurrency}
          on:click={() => (selectedCurrencyError = false)} />
        USD</label>
    </div>
    {#if createAccountError}
      <div><span style="color:red">An error has occurred</span></div>
    {/if}
    {#if opHash}
      <div>
        <a
          href={`https://${$store.network === 'testnet' ? 'delphi.' : ''}tzkt.io/${opHash}`}
          target="_blank"
          rel="noopener noreferrer nofollower">View transaction</a>
      </div>
    {/if}
    <br />
    <div>
      <button
        class={`button info small ${!selectedCurrency ? 'disabled' : ''}`}
        class:loading={loadingCreateAccount}
        data-text={loadingCreateAccount ? 'Waiting' : 'Confirm'}
        disabled={loadingCreateAccount}
        on:click={createAccount}>{loadingCreateAccount ? 'Waiting' : 'Confirm'}</button>
    </div>
  {:else if $store.userRecipients.length === 0}
    <div>You currently have 0 recipients.</div>
    <br />
    <AddRecipient />
  {:else}
    <Recipients />
  {/if}
</div>
