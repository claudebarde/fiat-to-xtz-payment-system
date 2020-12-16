<script lang="ts">
    import { fly } from "svelte/transition";
</script>

<style lang="scss">
    .error {
        position: absolute;
        top: 40px;
        left: 0;
        right: 0;
        margin: auto;
        max-width: 300px;
        background-color: lighten(#fdaed4, 10);
        border: solid 2px lighten(#c54fa0, 10);
        color: lighten(#c54fa0, 10);
        border-radius: 1rem;
        padding: 10px 20px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }
</style>

<div class="error" transition:fly={{ y: -500, duration: 1000 }}>
    An error has occurred
</div>
