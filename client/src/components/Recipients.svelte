<script lang="ts">
  import store from "../store";
  import AddRecipient from "./AddRecipient.svelte";
  import RemoveRecipient from "./RemoveRecipient.svelte";
  import EditRecipient from "./EditRecipient.svelte";
  import SendPayment from "./SendPayment.svelte";
  import PaymentHistory from "./PaymentHistory.svelte";

  let selected = 1;
</script>

<style lang="scss">
  .tabs {
    display: flex;
    justify-content: space-between;
    width: 80%;
    position: absolute;
    top: 10px;

    .tab {
      width: 100%;
      text-align: center;
      padding: 5px;
      text-shadow: 1px 1px #333;
      cursor: pointer;
      border-bottom: solid 3px transparent;
      transition: 0.3s;
      font-size: 1rem;

      &#selected {
        border-bottom: solid 3px white;
      }
    }
  }

  .main {
    width: 80%;
    margin-top: calc(1rem + 30px);
    overflow: auto;
    position: relative;
  }

  .recipients {
    width: 100%;
    display: grid;
    grid-template-columns: 70% 15% 15%;
  }
</style>

<div class="tabs">
  <div
    class="tab"
    id={selected === 1 ? 'selected' : ''}
    on:click={() => (selected = 1)}>
    <i class="fas fa-users" />
  </div>
  <div
    class="tab"
    id={selected === 2 ? 'selected' : ''}
    on:click={() => (selected = 2)}>
    <i class="fas fa-user-plus" />
  </div>
  <div
    class="tab"
    id={selected === 3 ? 'selected' : ''}
    on:click={() => (selected = 3)}>
    <i class="fas fa-user-minus" />
  </div>
  <div
    class="tab"
    id={selected === 4 ? 'selected' : ''}
    on:click={() => (selected = 4)}>
    <i class="fas fa-user-edit" />
  </div>
  <div
    class="tab"
    id={selected === 5 ? 'selected' : ''}
    on:click={() => (selected = 5)}>
    <i class="far fa-paper-plane" />
  </div>
  <div
    class="tab"
    id={selected === 6 ? 'selected' : ''}
    on:click={() => (selected = 6)}>
    <i class="fas fa-history" />
  </div>
</div>

<div class="main">
  {#if selected === 1}
    <div style="text-align:center">
      {$store.userRecipients.length}
      recipient{$store.userRecipients.length > 1 ? 's' : ''}
    </div>
    <br />
    {#each $store.userRecipients as recipient}
      <div class="recipients">
        <div>
          <a
            href={`https://${$store.network === 'testnet' ? 'delphi.' : ''}tzkt.io/${recipient.address}`}
            target="_blank"
            rel="noopener noreferrer nofollower">{recipient.address.slice(0, 12) + '...' + recipient.address.slice(-12)}</a>
        </div>
        <div>{$store.userCurrency}</div>
        <div>{recipient.amount}</div>
      </div>
    {/each}
  {:else if selected === 2}
    <AddRecipient />
  {:else if selected === 3}
    <RemoveRecipient />
  {:else if selected === 4}
    <EditRecipient />
  {:else if selected === 5}
    <SendPayment />
  {:else if selected === 6}
    <PaymentHistory />
  {/if}
</div>
