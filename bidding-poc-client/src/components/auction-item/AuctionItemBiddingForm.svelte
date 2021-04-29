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
	export let ownerId = null
	export let lastBid = null

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

		if (currentBid < lastBid.amount) {
			if (currentBid) {
				toastr.warning("Your bid is too small (updated to the next minimal bid)")
				blockFor(3000)
			}
			// todo: Use Auction's min_step value when it becomes available
			currentBid = lastBid.amount
		}
	}

	function onFocusChanged(focused) {
		if (focused || !lastBid)
			return

		if (currentBid < lastBid.amount) {
			toastr.warning("Your bid is too small (updated to the next minimal bid)")
			// todo: Use Auction's min_step value when it becomes available
			currentBid = lastBid.amount
			blockFor(3000)
		}
	}

	function onPlaceBid() {
		// todo: Use Auction's min_step value when it becomes available
		if (!currentBid || currentBid <= 0 || (lastBid ? currentBid < lastBid.amount : false) || blocked)
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
		if (bid.amount > currentBid) {
			blockFor(3000)
			// todo: Use Auction's min_step value when it becomes available
			currentBid = bid.amount
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

<form class="mb-3" on:submit={onSubmit}>
	<div class="columns">
		<div class="column">
			{#if userStatus === "joined"}
				<NumberInput
					value={currentBid}
					label="Your bid"
					required
					isHorizontal
					on:focus={() => amountFocused = true}
					on:blur={() => amountFocused = false}
					on:input={({detail: d}) => currentBid = d}
				/>
			{/if}
		</div>
		{#if !isAuthor}
			<div class="column is-narrow">
				{#if userStatus === "joined"}
					<TheButton isLink disabled={blocked || isAuthorOfLastBid} on:click={onPlaceBid}>
						Place bid
					</TheButton>
					<TheButton isWarning disabled={isAuthorOfLastBid} on:click={onLeaveBidding}>
						Leave bidding
					</TheButton>
				{:else}
					<TheButton isPrimary on:click={onJoinBidding}>
						Join bidding
					</TheButton>
				{/if}
			</div>
		{/if}
	</div>
</form>
