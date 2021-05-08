<script>
	import {createEventDispatcher, onDestroy, onMount} from "svelte"
	import m from "moment"
	import {getAuctionItemUrl} from "../../routes"
	import {secondeer} from "../../stores/other"
	import {userStore} from "../../providers/auth"
	import {formatCounterDuration, toCountdown} from "../../helpers/date-duration"
	import AuctionQuickCardBidForm from "./AuctionQuickCardBidForm.svelte"
	import AucionQuickCardCountdown from "./AucionQuickCardCountdown.svelte"
	import AuctionQuickCardBidInfo from "./AuctionQuickCardBidInfo.svelte"

	const dispatch = createEventDispatcher()
	export let auction = null

	let remainingTime = "Unknown"
	let auctionStatus = null
	let secondeerSubscription
	let biddingEndCountdown

	$: formattedBiddingEnd = auction && m(auction.bidding_end).toString()
	$: biddingEnded = auction && m(auction.bidding_end).isBefore()
	$: biddingStarted = auction && m(auction.bidding_start).isBefore()
	$: auction.bidding_end && computeBiddingEndCountdown()

	function computeBiddingEndCountdown() {
		biddingEndCountdown = toCountdown(m(auction.bidding_end).diff()).filter(x => x).slice(null, 3)
	}

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
				remainingTime = formatCounterDuration(biddingStartDiff)
				auctionStatus = "not_started"
			} else if (biddingEndDiff > 0) {
				remainingTime = formatCounterDuration(biddingEndDiff)
				auctionStatus = "not_ended"
			} else {
				auctionStatus = "ended"
				setTimeout(() => {
					destroySubscription()
				}, 10)
			}

			computeBiddingEndCountdown()
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
				{#if auction.category}
					<span class="tag is-light is-info is-rounded mr-2">{auction.category}</span>
				{/if}
				<a href="#{getAuctionItemUrl(auction.id)}">
					{auction.title}
				</a>
<!--				<div class="columns is-fullwidth">-->
<!--					<div class="column p-1 is-narrow is-flex is-align-items-center">-->
						
						<!--{#if auction && auction.last_bid && auction.last_bid.amount}-->
						<!--	<span-->
						<!--		class="tag is-light is-primary is-rounded ml-1"-->
						<!--		title="The last bid for this auction"-->
						<!--	>Last bid: {auction && auction.last_bid.amount}</span>-->
						<!--{/if}-->
						<!--<span
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
						</span>-->
<!--					</div>-->
<!--				</div>-->
			</div>
			<span class="card-header-icon">
				<button class="delete has-background-danger"></button>
			</span>
		</header>
		<div class="card-content">
			<div class="content">
				<div class="columns">
					<div class="column">
						<AuctionQuickCardBidInfo
							lastBid={auction.last_bid}
							averageBidAmount={auction.average_bid}
						/>
					</div>
					<div class="column">
						{#if !biddingStarted || biddingEnded} 
							<div class="has-text-centered"><b class="is-size-3">---</b></div>
						{:else}
							<AucionQuickCardCountdown {biddingEndCountdown} />
						{/if}
					</div>
				</div>
			</div>
			{#if !biddingStarted}
				<span class="is-size-5">Bidding has not started yet</span>
			{:else if biddingEnded}
				<span class="is-size-5">
					Bidding has ended.
					{#if auction.last_bid && auction.last_bid.user_id === $userStore.id}
					You have won!	
					{/if}
				</span>
			{:else}
				<hr>
				<AuctionQuickCardBidForm
					auctionId={auction.id}
					userStatus={auction.user_status}
					ownerId={auction.user_id}
					lastBid={auction.last_bid}
					minimumBidStep={auction.minimum_bid_step}
					on:placeBid
				/>
			{/if}
		</div>
		<!--{#if ["nothing", "following"].includes(auction.user_status)}-->
		<!--	<footer class="card-footer">-->
		<!--		&lt;!&ndash; todo: Render if user is owner/admin &ndash;&gt;-->
		<!--		&lt;!&ndash;<a href="#" class="card-footer-item">Edit</a>&ndash;&gt;-->
		
		<!--		<a-->
		<!--			href="javascript:void(0);"-->
		<!--			class="card-footer-item"-->
		<!--			on:click={() => dispatch("toggleFollow")}-->
		<!--		>-->
		<!--			{#if auction.user_status === "following"}-->
		<!--				UnFollow-->
		<!--			{:else if auction.user_status === "nothing"}-->
		<!--				Follow-->
		<!--			{/if}-->
		<!--		</a>-->
		<!--	</footer>-->
		<!--{/if}-->
	</div>
{/if}

<style lang="sass">
	.is-fullwidth
		width: calc(100% + 1.5rem)

	.card-content
		padding: .75rem
</style>
