<script>
	import {createEventDispatcher, onDestroy, onMount} from "svelte"
	import toastr from "../../helpers/toastr-helpers"
	import eventBus from "../../helpers/event-bus"
	import {userStore} from "../../providers/auth"
	import NumberInput from "../forms/NumberInput.svelte"
	import TheButton from "../ui/TheButton.svelte"

	const dispatch = createEventDispatcher()

	export let userStatus = "nothing"
	export let auctionId = null
	export let minimumBidStep = 0
	export let ownerId = null
	export let lastBid = null
	export let compact = false

	let currentBid = 0
	let amountFocused = false
	let blocked = false

	$: onLastBidChanged(lastBid)
	$: onFocusChanged(amountFocused)

	$: isAuthor = $userStore && $userStore.id === ownerId
	$: isAuthorOfLastBid = (lastBid && lastBid.user_id) === ($userStore && $userStore.id || "not_matching")

	function onLastBidChanged(bid) {
		if (amountFocused || !bid)
			return

		if (currentBid < lastBid.amount + minimumBidStep) {
			if (currentBid) {
				toastr.warning("Your bid is too small (updated to the next minimal bid)")
				blockFor(1000)
			}
			currentBid = lastBid.amount + minimumBidStep
		}
	}

	function onFocusChanged(focused) {
		if (focused || !lastBid)
			return

		if (currentBid < lastBid.amount + minimumBidStep) {
			toastr.warning("Your bid is too small (updated to the next minimal bid)")
			currentBid = lastBid.amount + minimumBidStep
			blockFor(1000)
		}
	}

	function onPlaceBid() {
		if (!currentBid || currentBid <= 0 || (lastBid ? currentBid < (lastBid.amount + minimumBidStep) : false) || blocked)
			return

		dispatch("placeBid", currentBid)
	}

	function onPlaceBidSuccess(itemBid) {
		toastr.success(`Bid ${itemBid.amount} placed successfully`)
	}

	function onJoinBidding() {
		dispatch("joinBidding")
	}

	function onLeaveBidding() {
		if (isAuthorOfLastBid) {
			toastr.warning("Your bid is last (cannot leave when you placed last bid)")
			return
		}
		dispatch("leaveBidding")
	}

	function onSubmit(ev) {
		ev.preventDefault()

		if (isAuthorOfLastBid) {
			toastr.warning("Your bid is last (cannot place another one right now)")
			return
		}

		onPlaceBid()
	}

	function onBidPlaced(bid) {
		if (bid.amount + minimumBidStep > currentBid) {
			blockFor(1000)
			currentBid = bid.amount + minimumBidStep
		}
	}

	function eventBusListeners(add = false) {
		const fn = add && "on" || "detach"

		const action = (e, callback) =>
			eventBus[fn](e + ":" + auctionId, callback)

		action("bid_placed", onBidPlaced)
		action("place_bid_success", onPlaceBidSuccess)
	}

	function blockFor(amount) {
		if (blocked)
			return

		blocked = true
		setTimeout(() => {
			blocked = false
		}, amount)
	}

	onMount(() => {
		eventBusListeners(true)
	})

	onDestroy(() => {
		eventBusListeners()
	})
</script>

{#if !isAuthor}
	<form class="mb-3" on:submit={onSubmit}>
		<div class="columns">
			<div class="column">
				{#if userStatus === "joined"}
					<NumberInput
						value={currentBid}
						label={!compact && "Your bid" || ""}
						placeholder="Your bid"
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
					<TheButton
						isLink
						disabled={blocked || isAuthorOfLastBid}
						title={isAuthorOfLastBid && "Cannot place bid because you are the author of last bid" || (blocked && "Amount has been automatically updated. Check new amount") || null}
						on:click={onPlaceBid}
					>
						Place bid
					</TheButton>
					<!--{#if !compact}-->
					<TheButton
						isWarning
						disabled={isAuthorOfLastBid}
						title={isAuthorOfLastBid && "You are the author of last bid - cannot leave auction now" || null}
						on:click={onLeaveBidding}
					>
						Leave bidding
					</TheButton>
					<!--{/if}-->
				{:else}
					<!--{#if !compact}-->
					<TheButton
						isPrimary
						on:click={onJoinBidding}
					>
						Join bidding
					</TheButton>
					<!--{/if}-->
				{/if}
			</div>
		</div>
	</form>
{/if}
