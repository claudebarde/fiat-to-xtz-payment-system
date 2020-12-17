<script lang="ts">
    import { onMount } from "svelte";
    import store from "../store";
    import { Payment } from "../types";
    import { fromFiatToXTZ } from "../utils";

    let payments: Payment[] = [];
    let loadingPayments = true;

    onMount(async () => {
        if ($store.userAddress) {
            const url = `https://api.better-call.dev/v1/contract/${
                $store.network === "testnet" ? "delphinet" : "mainnet"
            }/${
                $store.contractAddress[$store.network]
            }/operations?entrypoints=request_payment`;
            const data = await fetch(url);
            const json = await data.json();
            console.log(json);
            if (
                json.hasOwnProperty("operations") &&
                Array.isArray(json.operations)
            ) {
                // groups all the operations with the same transaction hash
                let currentOpHash = "";
                let payment: Payment;
                json.operations.forEach((op, i) => {
                    if (op.hash !== currentOpHash && !currentOpHash) {
                        // beginning of the loop
                        currentOpHash = op.hash;
                    } else if (op.hash !== currentOpHash && currentOpHash) {
                        // new transaction
                        payments = [...payments, payment];
                        payment = undefined;
                        currentOpHash = op.hash;
                    }

                    // first transaction, user sends request to contract
                    if (op.source === $store.userAddress) {
                        payment = {
                            opHash: op.hash,
                            totalAmount: op.amount,
                            fee: op.fee,
                            dispatchedAmounts: [],
                            timestamp: Date.parse(op.timestamp),
                            date: new Date(op.timestamp),
                            exchangeRate: null,
                            fiat: "",
                        };
                    }

                    // third transaction, oracle sends back data
                    if (op.source === $store.oracleAddress[$store.network]) {
                        if (
                            op.hasOwnProperty("parameters") &&
                            op.parameters.hasOwnProperty("children") &&
                            Array.isArray(op.parameters.children) &&
                            op.parameters.children.length === 3
                        ) {
                            const pair = op.parameters.children.filter(
                                (p) => p.prim === "string"
                            )[0];
                            const timestamp = op.parameters.children.filter(
                                (p) => p.prim === "timestamp"
                            )[0];
                            const rate = op.parameters.children.filter(
                                (p) => p.prim === "nat"
                            )[0];

                            payment.exchangeRate = {
                                pair: pair.value,
                                timestamp: Date.parse(timestamp.value),
                                rate: +rate.value,
                            };
                            // determines fiat currency
                            const arr = pair.value.split("-");
                            if (arr[0] === "XTZ") {
                                payment.fiat = arr[1];
                            } else {
                                payment.fiat = arr[0];
                            }
                        }
                    }

                    // any transaction sent to a recipient
                    if (
                        op.destination.slice(0, 2) === "tz" &&
                        op.hasOwnProperty("amount") &&
                        op.source === $store.contractAddress[$store.network]
                    ) {
                        payment.dispatchedAmounts = [
                            ...payment.dispatchedAmounts,
                            { amount: op.amount, to: op.destination },
                        ];
                    }

                    // pushes last payment into array
                    if (i === json.operations.length - 1) {
                        payments = [...payments, payment];
                    }
                });
            }
            store.updatePayments(payments);
            loadingPayments = false;
        }
    });
</script>

<style lang="scss">
    .payment-history {
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .payment-row {
        display: grid;
        grid-template-columns: 40% 50% 10%;
        width: 90%;
    }

    .full-history {
        text-decoration: underline;
        cursor: pointer;
        font-size: 0.8rem;
    }
</style>

<div class="payment-history">
    <div>Payments History</div>
    <div class="full-history" on:click={() => store.showPaymentsHistory(true)}>
        Full History
        <i class="fas fa-list" />
    </div>
    <br />
    {#if loadingPayments}
        <div>Loading Payments History...</div>
    {:else}
        {#each payments as payment}
            <div class="payment-row">
                <div>
                    -
                    {payment.date.getMonth() + 1}/{payment.date.getDate()}/{payment.date.getFullYear()}
                </div>
                <div>
                    XTZ
                    {(payment.totalAmount / 10 ** 6).toFixed(2)}
                    /
                    {payment.fiat}
                    {fromFiatToXTZ(payment.exchangeRate.rate, payment.totalAmount)}
                </div>
                <div>({payment.dispatchedAmounts.length})</div>
            </div>
        {:else}
            <div>No payment yet</div>
        {/each}
    {/if}
</div>
