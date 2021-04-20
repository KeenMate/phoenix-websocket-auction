<script>
	import {createEventDispatcher} from "svelte"
	import NumberInput from "../forms/NumberInput.svelte"
	import TheButton from "../ui/TheButton.svelte"

	export let userJoined = false

	let currentBid = 0

	const dispatch = createEventDispatcher()

	function onPlaceBid() {
		if (!currentBid)
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

	// function onSubmit(ev) {
	// 	ev.preventDefault()
	//
	// 	if (userJoined)
	// 		currentBid && onPlaceBid()
	// 	else
	// 		onJoinBidding()
	// }
</script>

<div class="mb-3">
	<div class="columns">
		<div class="column">
			{#if userJoined}
				<NumberInput
					value={currentBid}
					label="Your bid"
					required
					isHorizontal
					on:input={({detail: d}) => currentBid = d}
				/>
			{/if}
		</div>
		<div class="column is-narrow">
			{#if userJoined}
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
</div>
