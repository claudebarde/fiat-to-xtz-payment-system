<script lang="ts">
  import { onMount } from "svelte";
  import { fly } from "svelte/transition";
  import { TezosToolkit } from "@taquito/taquito";
  import store from "./store";
  import { BeaconWallet } from "@taquito/beacon-wallet";
  import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
  import { NetworkType } from "@airgap/beacon-sdk";
  import BigNumber from "bignumber.js";
  import UserInterface from "./components/UserInterface.svelte";
  import FullPaymentsHistory from "./components/FullPaymentsHistory.svelte";
  import ErrorToast from "./components/ErrorToast.svelte";

  const connectWallet = async () => {
    const wallet = new BeaconWallet({
      name: "Tezos Payment System",
      eventHandlers: {
        PERMISSION_REQUEST_SENT: {
          // setting up the handler method will disable the default one
          handler: async (data) => {
            console.log("permission request");
          },
        },
        // To enable your own wallet connection success message
        PERMISSION_REQUEST_SUCCESS: {
          // setting up the handler method will disable the default one
          handler: async (data) => {
            console.log("wallet connected");
          },
        },
        OPERATION_REQUEST_SENT: {
          // setting up the handler method will disable the default one
          handler: async (data) => {
            console.log("request sent", data);
          },
        },
        OPERATION_REQUEST_SUCCESS: {
          // setting up the handler method will disable the default one
          handler: async (data) => {
            console.log("request success", data);
          },
        },
        PAIR_SUCCESS: {
          // setting up the handler method will disable the default one
          handler: async (data) => {
            console.log("permission request");
          },
        },
        BROADCAST_REQUEST_SENT: {
          handler: async (data) => {
            console.log("broadcast request:", data);
          },
        },
        BROADCAST_REQUEST_SUCCESS: {
          // setting up the handler method will disable the default one
          handler: async (data) => {
            console.log("broadcast request success");
          },
        },
      },
    });
    let networkType = NetworkType.CUSTOM;
    if ($store.network === "testnet") {
      networkType = NetworkType.DELPHINET;
    } else if ($store.network === "mainnet") {
      networkType = NetworkType.MAINNET;
    }
    await wallet.requestPermissions({ network: { type: networkType } });
    const userAddress = await wallet.getPKH();
    store.updateUserAddress(userAddress);

    // checks if user is registered in the contract
    const recipients = await $store.contractStorage.recipients.get(userAddress);
    if (recipients) {
      store.updateUserCurrency(recipients[0]);

      const addresses: { address: string; amount: number }[] = [];
      recipients[1].forEach((val: BigNumber, key: string) => {
        addresses.push({ address: key, amount: val.toNumber() });
      });
      store.updateRecipients(addresses);
    }

    // updates the state of the dapp
    $store.Tezos.setWalletProvider(wallet);
    store.updateWallet(wallet);
  };

  const connectTezBridge = async () => {
    const wallet = new TezBridgeWallet();
    const userAddress = await wallet.getPKH();
    store.updateUserAddress(userAddress);
    // checks if user is registered in the contract
    const recipients = await $store.contractStorage.recipients.get(userAddress);
    if (recipients) {
      store.updateUserCurrency(recipients[0]);

      const addresses: { address: string; amount: number }[] = [];
      recipients[1].forEach((val: BigNumber, key: string) => {
        addresses.push({ address: key, amount: val.toNumber() });
      });
      store.updateRecipients(addresses);
    }

    // updates the state of the dapp
    $store.Tezos.setWalletProvider(wallet);
  };

  const disconnectWallet = async () => {
    $store.wallet.client.destroy();
    store.updateUserAddress(undefined);
    store.updateWallet(undefined);
  };

  onMount(async () => {
    const tezos = new TezosToolkit($store.rpcUrl[$store.network]);
    store.updateTezos(tezos);
    const contract = await tezos.wallet.at(
      $store.contractAddress[$store.network]
    );
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
    position: relative;
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

  .slide-top {
    margin-bottom: -100px;
    -webkit-animation: slide-top 1s cubic-bezier(0.25, 0.46, 0.45, 0.94) both;
    animation: slide-top 1s cubic-bezier(0.25, 0.46, 0.45, 0.94) both;
  }

  .slide-bottom {
    margin-top: -100px;
    -webkit-animation: slide-bottom 1s cubic-bezier(0.25, 0.46, 0.45, 0.94) both;
    animation: slide-bottom 1s cubic-bezier(0.25, 0.46, 0.45, 0.94) both;
  }
</style>

<main>
  <div class="containers-wrapper">
    <div
      class={`container ${$store.userAddress ? 'slide-top' : ''}`}
      in:fly={{ x: -1000, duration: 2500, delay: 200 }}>
      <h1>Fiat to XTZ</h1>
      <h1>Payment System</h1>
    </div>
    {#if $store.userAddress}
      <UserInterface />
    {/if}
    <div
      class={`container ${$store.userAddress ? 'slide-bottom' : ''}`}
      transition:fly={{ x: 1000, duration: 2500, delay: 200 }}>
      {#if !$store.userAddress}
        <h3>Start here and connect your wallet</h3>
        <button
          class="button info"
          data-text="Connect"
          on:click={connectWallet}>Connect</button>
        {#if process.env.NODE_ENV === 'development'}
          <br />
          <div
            style="font-size:0.8rem;cursor:pointer"
            on:click={connectTezBridge}>
            Connect with TezBridge
          </div>
        {/if}
      {:else}
        <h3>
          Connected as
          {$store.userAddress.slice(0, 7) + '...' + $store.userAddress.slice(-7)}
        </h3>
        <button
          class="button error"
          data-text="Disconnect"
          on:click={disconnectWallet}>Disconnect</button>
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
{#if $store.fullPaymentsHistory}
  <FullPaymentsHistory />
{/if}
{#if $store.error.show}
  <ErrorToast />
{/if}
