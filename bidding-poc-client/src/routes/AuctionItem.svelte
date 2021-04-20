<script>
	import {onDestroy} from "svelte"
	import {pop} from "svelte-spa-router"
	import m from "moment"
	import {socket} from "../providers/socket/common"
	import {deleteAuction} from "../providers/socket/auction"
	import {initBiddingChannel, joinBidding, leaveBidding, placeBid} from "../providers/socket/bidding"
	import toastr from "../helpers/toastr-helpers"
	import eventBus from "../helpers/event-bus"
	import {minuteer} from "../stores/other"
	import Notification from "../components/ui/Notification.svelte"
	import AuctionItemDetail from "../components/auction-item/AuctionItemDetail.svelte"
	import AuctionItemBiddings from "../components/auction-item/AuctionItemBiddings.svelte"
	import AuctionItemBiddingForm from "../components/auction-item/AuctionItemBiddingForm.svelte"
	import AuctionItemActiveUsers from "../components/auction-item/AuctionItemActiveUsers.svelte"

	export let params = {}

	// auction item
	let auctionItemChannel
	let auctionItem = {}
	let users = null
	let biddings = []

	$: paramAuctionItemId = Number(params.id)

	$: $socket && initBiddingChannel($socket, paramAuctionItemId,
		{
			onAuctionItem: item => auctionItem = item,
			onBiddings: payload => biddings = payload.biddings
		})
		.then(({channel, users: usersStore}) => {
			users = usersStore
			auctionItemChannel = channel
		})
		.catch(({channel, error}) => {
			console.error("Could not initiate auction item channel", error)
			toastr.error("Could not open connection for this auction item")
			
			auctionItemChannel = channel
		})

	$: $minuteer && (biddings = biddings)

	$: noBidding = m(auctionItem.bidding_start).isAfter() || m(auctionItem.bidding_end).isBefore()

	eventBus.on("place_bid_error", onPlaceBidError)
	eventBus.on("bid_placed_success", onPlaceBidSuccess)
	eventBus.on("bid_placed", onBidPlaced)
	eventBus.on("user_joined", onUserJoined)
	eventBus.on("item_removed", onItemRemoved)

	function onItemRemoved(msg) {
		if (msg.item_id !== paramAuctionItemId)
			return
		
		toastr.error("This auction item has been removed")
	}
	
	function onBidPlaced(bid) {
		console.log("bidPlaced: ", bid)
		if (!auctionItem)
			return

		biddings = [bid, ...(biddings || [])]
	}

	function onUserJoined(user) {
		console.log("userJoined: ", user)
		if (!auctionItem)
			return
	}

	function onJoinBidding() {
		if (!auctionItemChannel) {
			console.warn("Could not join bidding because there is no auction channel available")
			return
		}

		joinBidding(auctionItemChannel)
			.then(() => {
				toastr.success("Auction joined!")
				console.log("Auction joined")
				auctionItem.user_joined = true
			})
			.catch(error => {
				console.error("Could not join auction", error)
				toastr.error("Could not join auction")
			})
	}
	
	function onLeaveBidding() {
		if (!auctionItemChannel) {
			console.warn("Could not leave bidding because there is no auction channel available")
			return
		}

		leaveBidding(auctionItemChannel)
			.then(() => {
				toastr.success("Auction left!")
				console.log("Auction left")
				auctionItem.user_joined = false
			})
			.catch(error => {
				console.error("Could not leave auction", error)
				toastr.error("Could not leave auction")
			})
	}

	function onPlaceBid({detail: bid}) {
		placeBid(auctionItemChannel, bid)
			.then(() => {
				toastr.success("Bid place requested", {timeOut: "1000"})
				// onBidPlaced(newBid)
			})
			.catch(error => {
				console.error("Could not place bid", error)
				toastr.error("Could not place bid", {timeOut: "5000"})
			})
	}

	function onPlaceBidSuccess() {
		toastr.success("Bid placed successfully")
	}

	function onPlaceBidError(error) {
		switch (error.reason) {
			case "small_bid":
				toastr.error("Bid you have entered is too small")
				break
			case "not_found":
				toastr.error("Bid could not be placed because auction was not found (probably deleted)")
				break
			case "item_postponed":
				toastr.error("Bid could not be placed because auction has not started yet")
				break
			case "bidding_ended":
				toastr.error("Bid could not be placed because auction has already ended")
				break

			default:
				toastr.error("Bid could not be placed")
				console.error("Could not place bid", error)
		}
	}

	function onDeleteAuction() {
		deleteAuction(paramAuctionItemId)
			.then(() => {
				toastr.success("Auction item deleted")
				pop()
			})
			.catch(error => {
				switch (error) {
					case "forbidden":
						toastr.error("You are not allowed to delete this auction")
						break
					default:
						toastr.error("Could not delete this auction")
				}
			})
	}

	onDestroy(() => {
		if (auctionItemChannel) {
			auctionItemChannel.leave()
		}

		eventBus.detach("bid_placed", onBidPlaced)
		eventBus.detach("bid_placed_success", onPlaceBidSuccess)
		eventBus.detach("place_bid_error", onPlaceBidError)
		eventBus.detach("user_joined", onUserJoined)
		eventBus.detach("item_removed", onItemRemoved)
	})
</script>

<section class="auction-item">
	<div class="columns is-centered">
		<div class="column is-4">
			{#if !auctionItem}
				<Notification>Loading auction item</Notification>
			{:else}
				<AuctionItemDetail
					{...auctionItem}
					on:deleteAuction={onDeleteAuction}
				/>
			{/if}
		</div>
		<div class="column is-6">
			{#if noBidding }
				<Notification>
					Bidding not available
				</Notification>
			{:else}
				<AuctionItemBiddingForm
					userJoined={auctionItem.user_joined}
					on:joinBidding={onJoinBidding}
					on:leaveBidding={onLeaveBidding}
					on:placeBid={onPlaceBid}
				/>
			{/if}

			<AuctionItemBiddings {biddings}/>
		</div>
		<div class="column is-2">
			<AuctionItemActiveUsers users={users && $users}/>
		</div>
	</div>
</section>
