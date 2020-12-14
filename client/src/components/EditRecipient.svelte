<script lang="ts">
    import { validateAddress } from "@taquito/utils";
    import store from "../store";

    let recipientToEdit = "";
    let recipientAmount = "";
    let loadingRecipientToEdit = false;

    const updateRecipientAmount = (e: Event) => {
        const val = (e.target as HTMLInputElement).value;
        recipientAmount = val;
    };

    const editRecipient = async () => {
        loadingRecipientToEdit = true;

        try {
            if (validateAddress(recipientToEdit) !== 3)
                throw "Wrong address format";

            const op = await $store.contract.methods
                .update_recipient(recipientToEdit, recipientAmount)
                .send();
            await op.confirmation();
            // update recipients list
            const newRecipients = $store.userRecipients.map((r) => {
                if (r.address === recipientToEdit) {
                    return { ...r, amount: +recipientAmount };
                } else {
                    return r;
                }
            });
            store.updateRecipients(newRecipients);
            recipientToEdit = "";
            recipientAmount = "";
        } catch (error) {
            console.log(error);
        } finally {
            loadingRecipientToEdit = false;
        }
    };
</script>

<style lang="scss">
    .recipient {
        display: grid;
        grid-template-columns: 5% 65% 10% 20%;
        align-items: center;
        width: 100%;
    }

    .checkbox {
        margin: 0px;
        margin-right: 10px;
        cursor: pointer;
        background-color: transparent;
    }

    .update-recipient {
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        align-items: center;
    }

    .edit-recipient-amount {
        width: 60px;
    }
</style>

<div class="update-recipient">
    <div>Edit recipient</div>
    <br />
    {#each $store.userRecipients as recipient}
        <div class="recipient">
            <div
                class="checkbox"
                on:click={() => {
                    if (!loadingRecipientToEdit) {
                        if (recipientToEdit !== recipient.address) {
                            recipientToEdit = recipient.address;
                        } else {
                            recipientToEdit = '';
                        }
                    }
                }}>
                {#if recipientToEdit === recipient.address}
                    <i class="fas fa-check" />
                {:else}<i class="far fa-square" />{/if}
            </div>
            <div>
                {recipient.address.slice(0, 12) + '...' + recipient.address.slice(-12)}
            </div>
            <div>{$store.userCurrency}</div>
            <div>
                <input
                    type="text"
                    value={recipient.amount}
                    class="edit-recipient-amount"
                    disabled={recipient.address !== recipientToEdit || loadingRecipientToEdit}
                    on:input={updateRecipientAmount} />
            </div>
        </div>
    {/each}
    <br />
    <button
        class={`button info small ${!recipientToEdit ? 'disabled' : ''}`}
        class:loading={loadingRecipientToEdit}
        data-text={loadingRecipientToEdit ? 'Waiting' : 'Edit'}
        disabled={loadingRecipientToEdit || !recipientToEdit}
        on:click={editRecipient}>{loadingRecipientToEdit ? 'Waiting' : 'Edit'}</button>
</div>
