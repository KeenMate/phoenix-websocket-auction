<script>
	import {createEventDispatcher, onDestroy, onMount} from "svelte"
	import eventBus from "../../helpers/event-bus"
	import NumberInput from "../forms/NumberInput.svelte"
	import TheButton from "../ui/TheButton.svelte"

	export let userStatus = "nothing"
	export let itemId = null

	let currentBid = 0
	let amountFocused = false

	const dispatch = createEventDispatcher()

	function onPlaceBid() {
		if (!currentBid || currentBid <= 0)
			return

		dispatch("placeBid", currentBid)
		currentBid = 0
	}

	function onJoinBidding() {
		dispatch("joinBidding")
	}

	function onLeaveBidding() {
		dispatch("leaveBidding")
	}

	function onSubmit(ev) {
		ev.preventDefault()

		if (userStatus === "joined")
			onPlaceBid()
		else
			onJoinBidding()
	}

	function onBidPlaced({itemId: bidPlacedItemId, msg: bid}) {
		if (bidPlacedItemId !== itemId || amountFocused)
			return

		currentBid = bid.amount
	}

	function eventBusListeners(add = false) {
		const method = add && "on" || "detach"
		eventBus[method]("bid_placed", onBidPlaced)
	}

	onMount(() => {
		eventBusListeners(true)
	})

	onDestroy(() => {
		eventBusListeners()
	})
</script>

<form class="mb-3" on:submit={onSubmit}>
	<div class="columns">
		<div class="column">
			{#if userStatus === "joined"}
				<NumberInput
					value={currentBid}
					label="Your bid"
					required
					isHorizontal
					on:focus={() => amountFocused = true}
					on:blur={() => amountFocused = false}
					on:input={({detail: d}) => currentBid = d}
				/>
			{/if}
		</div>
		<div class="column is-narrow">
			{#if userStatus === "joined"}
				<TheButton isLink on:click={onPlaceBid}>
					Place bid
				</TheButton>
				<TheButton isWarning on:click={onLeaveBidding}>
					Leave bidding
				</TheButton>
			{:else}
				<TheButton isPrimary on:click={onJoinBidding}>
					Join bidding
				</TheButton>
			{/if}
		</div>
	</div>
</form>
