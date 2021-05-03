<script>
	import m from "moment"
	import {secondeer} from "../../stores/other"
	import {formatDuration} from "../../helpers/date-duration"
	import AuctionItemBiddingForm from "./AuctionItemBiddingForm.svelte"
	import {onDestroy, onMount} from "svelte"

	export let auction = null
	export let lastBid = null

	let remainingTime = "Unknown"
	let ended = true
	let secondeerSubscription

	$: formattedBiddingEnd = auction && m(auction.bidding_end).toString()

	function destroySubscription() {
		secondeerSubscription && secondeerSubscription()
	}

	onMount(() => {
		secondeerSubscription = secondeer.subscribe(() => {
			if (!auction)
				return

			const biddingEndDiff = m(auction.bidding_end).diff()
			if (biddingEndDiff > 0) {
				remainingTime = formatDuration(biddingEndDiff)
				ended = false
			}	else {
				ended = true
				destroySubscription()
			}
		})
	})

	onDestroy(() => {
		destroySubscription()
	})
</script>

{#if auction}
	<div class="card">
		<header class="card-header">
			<div class="card-header-title">
				<div class="columns is-fullwidth">
					<div class="column">
						{auction.title}
					</div>
					<div class="column is-narrow">
						{#if lastBid}
							<span
								class="tag is-light is-primary is-rounded ml-1"
								title="The last bid for this auction"
							>Last bid: {lastBid.amount}</span>
						{/if}
						<span
							class="tag is-light is-rounded ml-1"
							class:is-danger={ended}
							class:is-warning={!ended}
							title="Time left for this auction: {formattedBiddingEnd}"
						>
							{#if ended}
								Bidding ended
							{:else}
								Remaining: {remainingTime}
							{/if}
						</span>
					</div>
				</div>
			</div>
		</header>
		<div class="card-content">
			<div class="content">
				{#if auction.category}
					<span class="tag is-light is-info is-rounded mb-2">{auction.category}</span>
				{/if}
				{#if auction.user_status === "joined"}
				{/if}
				<AuctionItemBiddingForm
					auctionId={auction.id}
					userStatus={auction.user_status}
					ownerId={auction.user_id}
					minimumBidStep={auction.minimum_bid_step}
					compact
				/>
			</div>
		</div>
		<footer class="card-footer">
			<!-- todo: Render if user is owner/admin -->
			<a href="#" class="card-footer-item">Edit</a>

			<a href="#" class="card-footer-item">UnFollow</a>
		</footer>
	</div>
{/if}

<style lang="sass">
	.is-fullwidth
		width: calc(100% + 1.5rem)

	.card-content
		padding: .75rem
</style>
