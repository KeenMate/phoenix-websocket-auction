<script>
	import {createEventDispatcher} from "svelte"
	import m from "moment"
	import {userStore} from "../../providers/auth"
	import {minuteer} from "../../stores/other"
	import Card from "../ui/Card.svelte"
	import AuctionControls from "./AuctionControls.svelte"
	import UserLink from "./UserLink.svelte"

	const dispatch = createEventDispatcher()

	export let title = ""
	export let user_id = null
	export let category_id = 0
	export let category = ""
	export let description = ""
	export let inserted_at = null
	export let minimum_bid_step = 0
	export let bidding_start = null
	export let bidding_end = null
	export let user_status = "nothing"

	export let auctionOwner = null

	$: biddingStartMoment = bidding_start && m(bidding_start)
	$: biddingStartedRelative = $minuteer && biddingStartMoment && biddingStartMoment.fromNow()
	$: biddingEndMoment = bidding_end && m(bidding_end)
	$: biddingEndedRelative = $minuteer && biddingEndMoment && biddingEndMoment.fromNow()

	$: isAuthor = $userStore && $userStore.id === user_id

	function formatDateTime(val) {
		if (!val)
			return ""

		const date = new Date(val)

		return isNaN(date)
			? "Invalid date"
			: date.toLocaleString()
	}

	function getDateString(val) {
		const date = new Date(val)

		return isNaN(date)
			? "Invalid date"
			: date.toISOString().substr(0, 10)
	}

	function onDeleteClick() {
		if (!confirm("Do you really want to delete this auction?"))
			return

		dispatch("deleteAuction")
	}
</script>

<Card>
	{#if title || category_id}
		<div class="media">
			<div class="media-content">
				<div class="columns is-multiline is-justify-content-space-between">
					<div class="column is-12-mobile">
						{#if title}
							<p class="title is-4">{title}</p>
						{/if}
						{#if category_id}
							<p class="subtitle is-6">
								<span class="tag is-primary">{category}</span>
							</p>
						{/if}
						
					</div>
					<div class="column is-12-mobile">
						<AuctionControls
							userStatus={user_status}
							{isAuthor}
							on:toggleFollow
							on:delete={onDeleteClick}
						/>
					</div>
				</div>
			</div>
		</div>
	{/if}

	<div class="content">
		{#if bidding_start}
			<b>Bidding start: </b>
			{biddingStartMoment.calendar()} <i>({biddingStartedRelative})</i>
			<br>
		{/if}
		{#if bidding_end}
			<b>Bidding end: </b>
			{biddingEndMoment.calendar()} <i>({biddingEndedRelative})</i>
			<br>
		{/if}
		{#if description}
			<b>Description: </b>
			{description}
			<br>
		{/if}
		<b>Minimum bid step: </b>
		{minimum_bid_step}
		<br>
		<b>Created: </b>
		{#if inserted_at}
			<time datetime={getDateString(inserted_at)}>{formatDateTime(inserted_at)}</time>
		{:else}
			Not available
		{/if}
		<br>
		<b>Creator: </b>
		{#if auctionOwner}
			<UserLink user={auctionOwner} />
			<br>
		{/if}
	</div>
</Card>
