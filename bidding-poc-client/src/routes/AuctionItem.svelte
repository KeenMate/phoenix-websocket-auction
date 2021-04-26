<script>
	import {onDestroy, onMount} from "svelte"
	import {pop} from "svelte-spa-router"
	import m from "moment"
	import {socket} from "../providers/socket/common"
	import {deleteAuction} from "../providers/socket/auction"
	import {initBiddingChannel, joinBidding, leaveBidding, placeBid, toggleWatch} from "../providers/socket/bidding"
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

	const channelListeners = {
		onAuctionItem: item => auctionItem = item,
		onBiddings: payload => biddings = payload.biddings
	}

	$: paramAuctionItemId = Number(params.id)

	$: $socket && initBiddingChannel($socket, paramAuctionItemId, channelListeners)
		.then(({channel, users: usersStore}) => {
			users = usersStore
			auctionItemChannel = channel
		})
		.catch(({channel, error}) => {
			console.error("Could not initiate auction item channel", error)

			if (error === "not_found") {
				channel.leave()
				toastr.error("This auction could not be found")
				return
			}

			toastr.error("Could not open connection for this auction item")

			auctionItemChannel = channel
		})

	$: $minuteer && (biddings = biddings)

	$: biddingEnded = m(auctionItem.bidding_end).isBefore()
	$: biddingNotStarted = m(auctionItem.bidding_start).isAfter()

	$: lastBid = biddings && biddings[0]

	function reassignAuctionItem() {
		auctionItem = auctionItem
	}

	function onBiddingStarted(item) {
		console.log("Bidding started", item)
		if (item.id !== paramAuctionItemId)
			return

		toastr.success(`Bidding has started for auction: ${item.title}`)
		reassignAuctionItem()
	}

	function onBiddingEnded(item) {
		if (item.id !== paramAuctionItemId)
			return

		toastr.warning(`Bidding has ended for auction: ${item.title}`)
		reassignAuctionItem()
	}

	function onItemRemoved(msg) {
		if (msg.item_id !== paramAuctionItemId)
			return

		toastr.error("This auction item has been removed")
	}

	function onBidPlaced({itemId, msg: bid}) {
		console.log("bidPlaced: ", bid)

		if (itemId !== paramAuctionItemId)
			return
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
				auctionItem.user_status = "joined"
			})
			.catch(error => {
				console.error("Could not join auction", error)
				toastr.error("Could not join auction")
			})
	}

	function onLeaveBidding() {
		if (!auctionItemChannel) {
			console.warn("Could not leave bidding because there is no auction channel available")
			toastr.warning("Connection not alive")
			return
		}

		leaveBidding(auctionItemChannel)
			.then(result => {
				switch (result) {
					case "removed":
						toastr.success("Auction left!")
						console.log("Auction left")
						auctionItem.user_status = "nothing"
						break

					case "bidding_left":
						toastr.success("Auction is now just watched")
						console.log("Auction is now just watched")
						auctionItem.user_status = "watching"
						break

					default:
						toastr.success("Auction left")
						console.log("Auction left but result is not known", result)
						auctionItem.user_status = "nothing"
						break
				}
			})
			.catch(error => {
				switch (error) {
					case "already_bidded":
						toastr.danger("Could not leave auction because you have already placed bid")
						console.error("Could not leave auction because you have already placed bid")
						break

					case "not_found":
						console.error("Could not leave auction because you are not part of it")
						toastr.error("Could not leave auction because you are not part of it")
						break

					default:
						console.error("Could not leave auction", error)
						toastr.danger("Could not leave auction")
						break
				}
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

	function onToggleWatch() {
		toggleWatch()
			.then(operation => {
				if (operation === "watching")
					toastr.success("Auction is now watched")
				else
					toastr.success("Auction is not watched anymore!")

				pop()
			})
			.catch(error => {
				console.error("Could not toggle watch", error)
				toastr.error("Could not toggle watch for this auction")
			})
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

	function eventBusListeners(add = false) {
		const fn = add && "on" || "detach"

		eventBus[fn]("bid_placed", onBidPlaced)
		eventBus[fn]("bid_placed_success", onPlaceBidSuccess)
		eventBus[fn]("place_bid_error", onPlaceBidError)
		eventBus[fn]("user_joined", onUserJoined)
		eventBus[fn]("item_removed", onItemRemoved)
		eventBus[fn]("bidding_started", onBiddingStarted)
		eventBus[fn]("bidding_ended", onBiddingEnded)
	}

	onMount(() => {
		eventBusListeners(true)
	})

	onDestroy(() => {
		console.log("Destroying auction item")
		if (auctionItemChannel) {
			auctionItemChannel.leave()
		}

		eventBusListeners()
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
					on:toggleWatch={onToggleWatch}
					on:deleteAuction={onDeleteAuction}
				/>
			{/if}
		</div>
		<div class="column is-6">
			{#if biddingEnded }
				<Notification>
					This auction has already ended
				</Notification>
			{:else if biddingNotStarted}
				<Notification>
					This auction has not started yet
				</Notification>
			{:else if auctionItemChannel}
				<AuctionItemBiddingForm
					itemId={auctionItem.id}
					userStatus={auctionItem.user_status}
					{lastBid}
					on:joinBidding={onJoinBidding}
					on:leaveBidding={onLeaveBidding}
					on:placeBid={onPlaceBid}
				/>
			{/if}

			<AuctionItemBiddings {biddings} />
		</div>
		<div class="column is-2">
			<AuctionItemActiveUsers users={users && $users}/>
		</div>
	</div>
</section>
