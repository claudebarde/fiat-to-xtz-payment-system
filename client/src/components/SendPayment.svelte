<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import store from "../store";

    let totalAmountInFiat = 0;
    let totalAmountInXtz = 0;
    let loadingSendPayment = false;
    let refreshInterval: NodeJS.Timeout;

    const refreshExchangeRate = async () => {
        const totalAmount = $store.userRecipients
            .map((r) => r.amount)
            .reduce((a, b) => a + b);
        // fetches exchange rate from oracle
        const oracle = await $store.Tezos.contract.at(
            $store.oracleAddress[$store.network]
        );
        const storage: any = await oracle.storage();
        const exchangeRate = await storage.assetMap.get(
            `XTZ-${$store.userCurrency}`
        );
        if (exchangeRate && exchangeRate.hasOwnProperty("computedPrice")) {
            totalAmountInFiat = totalAmount;
            totalAmountInXtz =
                totalAmount * exchangeRate.computedPrice.toNumber();
        }
    };

    const sendPayment = async () => {
        loadingSendPayment = true;

        try {
            const op = await $store.contract.methods
                .request_payment([["unit"]])
                .send({ amount: totalAmountInXtz, mutez: true });
            await op.confirmation();
        } catch (error) {
            console.log(error);
        } finally {
            loadingSendPayment = false;
        }
    };

    onMount(async () => {
        // calculates total amount in fiat to be sent
        if ($store.userRecipients) {
            refreshExchangeRate();
            refreshInterval = setInterval(refreshExchangeRate, 1000 * 60 * 5);
        } else {
            totalAmountInFiat = 0;
            totalAmountInXtz = 0;
        }
    });

    onDestroy(() => {
        clearInterval(refreshInterval);
    });
</script>

<style lang="scss">
    .send-payment {
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        align-items: center;
    }
</style>

<div class="send-payment">
    <div>Send payment</div>
    <br />
    <div>Total number of recipients: {$store.userRecipients.length}</div>
    <div>
        Total amount to send:
        {$store.userCurrency}
        {totalAmountInFiat}
        / XTZ
        {(totalAmountInXtz / 10 ** 6).toFixed(2)}
    </div>
    <br />
    <button
        class={`button info small`}
        class:loading={loadingSendPayment}
        data-text={loadingSendPayment ? 'Sending' : 'Send'}
        disabled={loadingSendPayment}
        on:click={sendPayment}>{loadingSendPayment ? 'Sending' : 'Send'}</button>
</div>
