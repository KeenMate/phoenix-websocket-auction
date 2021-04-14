<script>
	import {createEventDispatcher} from "svelte"
	import NumberInput from "../forms/NumberInput.svelte"
	import TheButton from "../ui/TheButton.svelte"

	export let userJoined = false

	let currentBid = 0

	const dispatch = createEventDispatcher()

	function onPlaceBid() {
		dispatch("placeBid", currentBid)
		currentBid = 0
	}

	function onJoinBidding() {
		dispatch("joinBidding")
	}

	function onSubmit(ev) {
		ev.preventDefault()

		if (userJoined)
			currentBid && onPlaceBid()
		else
			onJoinBidding()
	}
</script>
<form class="mb-3" on:submit={onSubmit}>
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
				<TheButton isLink>Place bid</TheButton>
			{:else}
				<TheButton isPrimary>Join bidding</TheButton>
			{/if}
		</div>
	</div>
</form>
