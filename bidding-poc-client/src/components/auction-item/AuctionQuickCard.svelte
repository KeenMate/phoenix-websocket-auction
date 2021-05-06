<script>
	import {onDestroy, onMount} from "svelte"
	import m from "moment"
	import {getAuctionItemUrl} from "../../routes"
	import {secondeer} from "../../stores/other"
	import {formatDuration} from "../../helpers/date-duration"
	import AuctionItemBiddingForm from "./AuctionItemBiddingForm.svelte"

	export let auction = null

	let remainingTime = "Unknown"
	let auctionStatus = null
	let secondeerSubscription

	$: formattedBiddingEnd = auction && m(auction.bidding_end).toString()

	function destroySubscription() {
		secondeerSubscription && secondeerSubscription()
	}

	onMount(() => {
		secondeerSubscription = secondeer.subscribe(() => {
			if (!auction)
				return

			const biddingStartDiff = m(auction.bidding_start).diff()
			const biddingEndDiff = m(auction.bidding_end).diff()
			if (biddingStartDiff > 0) {
				remainingTime = formatDuration(biddingStartDiff)
				auctionStatus = "not_started"
			} else if (biddingEndDiff > 0) {
				remainingTime = formatDuration(biddingEndDiff)
				auctionStatus = "not_ended"
			}	else {
				auctionStatus = "ended"
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
						<a href="#{getAuctionItemUrl(auction.id)}">
							{auction.title}
						</a>
					</div>
					<div class="column is-narrow">
						{#if auction && auction.last_bid}
							<span
								class="tag is-light is-primary is-rounded ml-1"
								title="The last bid for this auction"
							>Last bid: {auction && auction.last_bid.amount}</span>
						{/if}
						<span
							class="tag is-light is-rounded ml-1"
							class:is-danger={auctionStatus === "ended"}
							class:is-warning={auctionStatus !== "started"}
							title="Time left for this auction: {formattedBiddingEnd}"
						>
							{#if auctionStatus === "ended"}
								Bidding ended
							{:else if auctionStatus === "not_started"}
								Starts in: {remainingTime}
							{:else if auctionStatus === "not_ended"}
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
				{#if ["joined", "following"].includes(auction.user_status)}
					<AuctionItemBiddingForm
						auctionId={auction.id}
						userStatus={auction.user_status}
						ownerId={auction.user_id}
						minimumBidStep={auction.minimum_bid_step}
						compact
						on:placeBid
						on:joinBidding
						on:leaveBidding
					/>
				{/if}
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
