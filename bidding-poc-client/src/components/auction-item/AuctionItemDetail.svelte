<script>
	import {createEventDispatcher} from "svelte"
	import m from "moment"
	import Card from "../ui/Card.svelte"
	import TheButton from "../ui/TheButton.svelte"
	import {minuteer} from "../../stores/other"
	import AuctionControls from "./AuctionControls.svelte"

	const dispatch = createEventDispatcher()

	export let title = ""
	export let category_id = 0
	export let category = ""
	export let description = ""
	export let inserted_at = null
	export let bidding_start = null
	export let bidding_end = null
	export let user_status = "nothing"

	$: biddingStartMoment = bidding_start && m(bidding_start)
	$: biddingStartedRelative = $minuteer && biddingStartMoment && biddingStartMoment.fromNow()
	$: biddingEndMoment = bidding_end && m(bidding_end)
	$: biddingEndedRelative = $minuteer && biddingEndMoment && biddingEndMoment.fromNow()

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
				<div class="level">
					<div class="level-left is-block">
						{#if title}
							<p class="title is-4">{title}</p>
						{/if}
						{#if category_id}
							<p class="subtitle is-6">
								<span class="tag is-primary">{category}</span>
							</p>
						{/if}
					</div>
					<div class="level-right">
						<AuctionControls
							{user_status}
							on:toggleWatch
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
		<b>Inserted at: </b>
		{#if inserted_at}
			<time datetime={getDateString(inserted_at)}>{formatDateTime(inserted_at)}</time>
		{:else}
			Not available
		{/if}
	</div>
</Card>
