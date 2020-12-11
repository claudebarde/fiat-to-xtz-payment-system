<script lang="ts">
  import store from "../store";

  let recipientToRemove = "";
  let loadingRemoveRecipient = false;

  const removeRecipient = () => {
    console.log("remove");
  };
</script>

<style lang="scss">
  .recipient {
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .checkbox {
    margin: 0px;
    margin-right: 10px;
    cursor: pointer;
    background-color: transparent;
  }

  .remove-recipient {
    text-align: center;
  }
</style>

<div class="remove-recipient">
  <div style="text-align:center">Remove recipient:</div>
  <br />
  {#each $store.userRecipients as recipient}
    <div
      class="recipient"
      on:click={() => (recipientToRemove = recipient.address)}>
      <div class="checkbox">
        {#if recipientToRemove === recipient.address}
          <i class="fas fa-check" />
        {:else}<i class="far fa-square" />{/if}
      </div>
      {recipient.address.slice(0, 12) + '...' + recipient.address.slice(-12)}:
      {$store.userCurrency}
      {recipient.amount}
    </div>
  {/each}
  <br />
  <button
    class={`button info small ${!recipientToRemove ? 'disabled' : ''}`}
    class:loading={loadingRemoveRecipient}
    data-text={loadingRemoveRecipient ? 'Waiting' : 'Remove'}
    disabled={loadingRemoveRecipient || !recipientToRemove}
    on:click={removeRecipient}>{loadingRemoveRecipient ? 'Waiting' : 'Remove'}</button>
</div>
