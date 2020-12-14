<script lang="ts">
  import { validateAddress } from "@taquito/utils";
  import store from "../store";

  let recipientToRemove = "";
  let loadingRemoveRecipient = false;

  const removeRecipient = async () => {
    loadingRemoveRecipient = true;

    try {
      if (validateAddress(recipientToRemove) !== 3)
        throw "Wrong address format";

      const op = await $store.contract.methods
        .remove_recipient(recipientToRemove)
        .send();
      await op.confirmation();
      // update recipients list
      const newRecipients = $store.userRecipients.filter(
        (r) => r.address !== recipientToRemove
      );
      store.updateRecipients(newRecipients);
    } catch (error) {
      console.log(error);
    } finally {
      loadingRemoveRecipient = false;
    }
  };
</script>

<style lang="scss">
  .recipient {
    width: 100%;
    display: grid;
    grid-template-columns: 10% 70% 10% 10%;
  }

  .checkbox {
    margin: 0px;
    margin-right: 10px;
    cursor: pointer;
    background-color: transparent;
  }

  .remove-recipient {
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: center;
  }
</style>

<div class="remove-recipient">
  <div>Remove recipient:</div>
  <br />
  {#each $store.userRecipients as recipient}
    <div
      class="recipient"
      on:click={() => {
        if (!loadingRemoveRecipient) {
          if (recipientToRemove !== recipient.address) {
            recipientToRemove = recipient.address;
          } else {
            recipientToRemove = '';
          }
        }
      }}>
      <div class="checkbox">
        {#if recipientToRemove === recipient.address}
          <i class="fas fa-check" />
        {:else}<i class="far fa-square" />{/if}
      </div>
      <div>
        {recipient.address.slice(0, 12) + '...' + recipient.address.slice(-12)}
      </div>
      <div>{$store.userCurrency}</div>
      <div>{recipient.amount}</div>
    </div>
  {:else}
    <div>No recipient yet</div>
  {/each}
  <br />
  <button
    class={`button info small ${!recipientToRemove ? 'disabled' : ''}`}
    class:loading={loadingRemoveRecipient}
    data-text={loadingRemoveRecipient ? 'Waiting' : 'Remove'}
    disabled={loadingRemoveRecipient || !recipientToRemove}
    on:click={removeRecipient}>{loadingRemoveRecipient ? 'Waiting' : 'Remove'}</button>
</div>
