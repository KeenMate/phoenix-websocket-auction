<script>
	import AuctionQuickCard from "../auction-item/AuctionQuickCard.svelte"
	import Notification from "../ui/Notification.svelte"

	export let title = null
	export let auctions = []
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
					lastBid={auction.last_bid}
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
