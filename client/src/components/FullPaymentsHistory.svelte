<script lang="ts">
  import { fly, fade } from "svelte/transition";
  import store from "../store";
</script>

<style lang="scss">
  .wrapper {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100vh;
    z-index: 100;
    display: grid;
    place-items: center;
  }

  .background {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100vh;
    background-color: black;
    opacity: 0.5;
    z-index: 101;
  }

  .payment-history {
    z-index: 102;
    height: auto;
    max-height: 500px;
    width: 50%;
    background-color: #66d7eb8f;
    overflow: auto;
    padding: 20px 0px;
  }

  .payment-row {
    text-align: left;

    .recipient {
      margin-left: 25px;
    }
  }
</style>

<div class="wrapper">
  <div class="background" transition:fade={{ duration: 900 }} />
  <div
    class="container payment-history"
    transition:fly={{ y: -1000, duration: 900 }}>
    <h3>Payments History</h3>
    <div
      style="cursor:pointer"
      on:click={() => store.showPaymentsHistory(false)}>
      Back
      <i class="fas fa-undo" />
    </div>
    <br />
    {#each $store.payments as payment}
      <div class="payment-row">
        <div>
          <i class="fas fa-minus" />&nbsp; 1 payment on
          {payment.date.getMonth() + 1}/{payment.date.getDate()}/{payment.date.getFullYear()}
          for XTZ
          {(payment.totalAmount / 10 ** 6).toFixed(2)}
          /
          {payment.exchangeRate.pair.split('-')[1]}
          {payment.totalAmount / payment.exchangeRate.rate}
        </div>
        <div>
          &nbsp;&nbsp; Exchange rate:
          {payment.exchangeRate.rate / 10 ** 6}
          {payment.fiat}
          for 1 XTZ
        </div>
        <div>
          &nbsp;&nbsp; Network fee: XTZ
          {payment.fee / 10 ** 6}
          ({payment.fiat}
          {((payment.fee * payment.exchangeRate.rate) / 10 ** 12).toFixed(2)})
        </div>
        <div>
          &nbsp;&nbsp; Recipients ({payment.dispatchedAmounts.length}):
          {#each payment.dispatchedAmounts as tx}
            <div class="recipient">
              <div>
                XTZ
                {(tx.amount / 10 ** 6).toFixed(2)}
                ({payment.fiat}
                {(tx.amount / payment.exchangeRate.rate).toFixed(2)}) to
                {tx.to.slice(0, 10) + '...' + tx.to.slice(-10)}
              </div>
            </div>
          {/each}
        </div>
        <div>
          &nbsp;&nbsp;
          <a
            href={`https://better-call.dev${$store.network === 'testnet' ? '/delphinet' : ''}/opg/${payment.opHash}/contents`}
            target="_blank"
            rel="noopener noreferrer nofollower">View full transaction</a>
        </div>
      </div>
      <br />
    {:else}
      <div>No payment yet!</div>
    {/each}
  </div>
</div>
