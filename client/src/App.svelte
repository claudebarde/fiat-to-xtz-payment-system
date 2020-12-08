<script lang="ts">
  import { onMount } from "svelte";
  import { fly } from "svelte/transition";
  import { TezosToolkit } from "@taquito/taquito";
  import store from "./store";
  import { BeaconWallet } from "@taquito/beacon-wallet";
  import { NetworkType } from "@airgap/beacon-sdk";

  const connectWallet = async () => {
    const wallet = new BeaconWallet({
      name: "Tezos Payment System"
    });
    let networkType = NetworkType.CUSTOM;
    if ($store.network === "testnet") {
      networkType = NetworkType.DELPHINET;
    }
    await wallet.requestPermissions({ network: { type: networkType } });
    const userAddress = await wallet.getPKH();

    $store.Tezos.setWalletProvider(wallet);
    store.updateUserAddress(userAddress);
    store.updateWallet(wallet);
  };

  onMount(async () => {
    const network = "local";
    const tezos = new TezosToolkit($store.rpcUrl[network]);
    store.updateTezos(tezos);
    const contract = await tezos.contract.at($store.contractAddress[network]);
    store.updateContract(contract);
    const storage = await contract.storage();
    store.updateContractStorage(storage);
  });
</script>

<style lang="scss">
  main {
    height: 100vh;
    display: grid;
    place-items: center;
  }

  .containers-wrapper {
    width: 40%;
  }

  .container {
    background-color: rgba(255, 255, 255, 0.2);
    padding: 2rem;
    margin: 1rem;
    border-radius: 2rem;
    position: relative;
    z-index: 1;
    backdrop-filter: blur(30px);
    border: solid 2px transparent;
    background-clip: padding-box;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;

    h1 {
      font-size: 2rem;
      margin: 0px;
      margin-bottom: 10px;
      font-weight: normal;
      text-shadow: 1px 1px #333;
    }

    h3 {
      font-size: 1.3rem;
      font-weight: normal;
      margin: 0px;
      margin-bottom: 20px;
      text-shadow: 1px 1px #333;
    }
  }

  .taquito-logo {
    position: absolute;
    bottom: 10px;
    right: 10px;

    img {
      width: 60px;
      height: 60px;
    }
  }
</style>

<main>
  <div class="containers-wrapper">
    <div class="container" in:fly={{ x: -1000, duration: 2500, delay: 200 }}>
      <h1>Fiat to XTZ</h1>
      <h1>Payment System</h1>
    </div>
    <div class="container" in:fly={{ x: 1000, duration: 2500, delay: 200 }}>
      {#if !$store.userAddress}
        <h3>Start here and connect your wallet</h3>
        <button
          class="button info"
          data-text="Connect"
          on:click={connectWallet}>Connect</button>
      {:else}
        <p>Connected!</p>
      {/if}
    </div>
  </div>
</main>
<div class="taquito-logo" in:fly={{ y: 100, duration: 500, delay: 2500 }}>
  <a
    href="https://tezostaquito.io"
    target="_blank"
    rel="noreferrer noopener nofollower"><img
      src="images/Built-with-round.png"
      alt="built-with-taquito" /></a>
</div>
