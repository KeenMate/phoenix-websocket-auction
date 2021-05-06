<script>
	import AuctionQuickCard from "../auction-item/AuctionQuickCard.svelte"
	import Notification from "../ui/Notification.svelte"

	export let title = null
	export let auctions = []

	function onPlaceBid(auction, amount) {
		dispatch("placeBid", {
			auction,
			amount
		})
	}

	function onJoinBidding(auction) {
		dispatch("joinBidding", auction)
	}

	function onLeaveBidding(auction) {
		dispatch("leaveBidding", auction)
	}

</script>

{#if auctions && auctions.length}
	{#if title}
		<h2 class="subtitle mb-2 mt-4">{title}</h2>
	{/if}
	<div class="columns is-multiline">
		{#each auctions as auction}
			<div class="column is-3">
				<!-- todo: Add event listeners -->
				<AuctionQuickCard
					{auction}
					on:placeBid={({detail: d}) => onPlaceBid(auction, d)}
					on:joinBidding={() => onJoinBidding(auction)}
					on:leaveBidding={() => onLeaveBidding(auction)}
				/>
			</div>
		{:else}
			<div class="column">
				<Notification>
					No auctions to display
				</Notification>
			</div>
		{/each}
	</div>
{/if}
