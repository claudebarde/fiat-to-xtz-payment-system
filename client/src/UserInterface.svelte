<script lang="ts">
  import { onMount } from "svelte";
  import { fly } from "svelte/transition";
  import store from "./store";

  let selectedCurrency = "";
  let accountAddress = "";

  onMount(() => {
    if ($store.userAddress) accountAddress = $store.userAddress;
  });
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

  input[type="text"] {
    background-color: rgba(255, 255, 255, 0.2);
    border: none;
    padding: 5px;
    margin: 5px;
    outline: none;
    transition: 0.4s;
    color: #0380b3;

    &:focus {
      background-color: rgba(255, 255, 255, 0.5);
    }
  }
</style>

<div class="container" in:fly={{ x: -1000, duration: 2500, delay: 1000 }}>
  {#if $store.userRecipients === null}
    <h3>Create a new account</h3>
    <div class="currencies">
      <span>Currency:</span>
      <label
        for="currency-USD"
        id={selectedCurrency === 'USD' ? 'selected' : ''}><input
          type="radio"
          name="currency"
          id="currency-USD"
          value="USD"
          bind:group={selectedCurrency} />
        USD</label>
    </div>
    <div>
      <span>Address:</span>
      <input type="text" bind:value={accountAddress} />
    </div>
    <br />
    <div>
      <button
        class={`button info small ${!selectedCurrency && !accountAddress ? 'disabled' : ''}`}
        data-text="Confirm">Confirm</button>
    </div>
  {:else}
    <div>Recipients here</div>
  {/if}
</div>
