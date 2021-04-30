<script>
	import {onDestroy, onMount} from "svelte"
	import {pop} from "svelte-spa-router"
	import m from "moment"
	import {socket} from "../providers/socket/common"
	import {userStore} from "../providers/auth"
	import {deleteAuction} from "../providers/socket/auctions"
	import {
		getAuctionBids,
		initAuctionChannels,
		joinAuction,
		leaveAuction,
		placeBid,
		toggleFollow
	} from "../providers/socket/auction"
	import toastr from "../helpers/toastr-helpers"
	import eventBus from "../helpers/event-bus"
	import {minuteer} from "../stores/other"
	import Notification from "../components/ui/Notification.svelte"
	import AuctionItemDetail from "../components/auction-item/AuctionItemDetail.svelte"
	import AuctionItemBiddings from "../components/auction-item/AuctionItemBiddings.svelte"
	import AuctionItemBiddingForm from "../components/auction-item/AuctionItemBiddingForm.svelte"
	import AuctionItemActiveUsers from "../components/auction-item/AuctionItemActiveUsers.svelte"
	import {getUser} from "../providers/socket/user"

	export let params = {}

	// channels
	let auctionChannel
	let biddingChannel
	let presenceChannel

	// auction item
	let auctionItem = {}
	let auctionOwner = null
	let users = null
	let biddings = []

	$: paramAuctionItemId = Number(params.id)

	$: initChannels($socket, paramAuctionItemId)

	$: $minuteer && (biddings = biddings)
	$: biddingEnded = m(auctionItem.bidding_end).isBefore()
	$: biddingStarted = m(auctionItem.bidding_start).isBefore()

	$: lastBid = biddings && biddings[0]

	$: isAuthor = (auctionItem && $userStore) && auctionItem.user_id === $userStore.id
	$: getAuctionOwner(auctionItem)

	function getAuctionOwner(auction) {
		if (!auction || !auction.user_id)
			return

		getUser(auction.user_id)
			.then(user => auctionOwner = user)
			.catch(error => {
				console.error("Could not load auction owner", error, auction)
				toastr.error("Could not load auction owner info")
			})
	}
	
	function reassignAuctionItem() {
		auctionItem = auctionItem
	}

	function initChannels(theSocket, auctionId) {
		theSocket && initAuctionChannels(theSocket, auctionId)
			.then(result => {
				const {
					auction,
					bidding,
					presence: {
						channel: presence,
						users: usersStore
					}
				} = result

				users = usersStore
				auctionChannel = auction
				biddingChannel = bidding
				presenceChannel = presence

				getBids(bidding)
			})
			.catch(error => {
				console.error("Could not initiate auction item channels", error)

				if (error.reason === "not_found") {
					error.channel.leave()
					toastr.error("This auction could not be found")
					return
				}

				toastr.error("Could not open connection for this auction item")
			})
	}

	function getBids(biddingChannel) {
		getAuctionBids(biddingChannel)
		.then(bids => {
			biddings = bids
		})
		.catch(error => {
			console.error("Could not load auction bids", error)
			toastr.error("Could not load auction bids")
		})
	}

	function onBiddingStarted() {
		console.log("Bidding started")

		toastr.success(`Bidding has started for auction: ${auctionItem.title}`)
		reassignAuctionItem()
	}

	function onBiddingEnded(item) {
		toastr.warning(`Bidding has ended for auction: ${item.title}`)
		reassignAuctionItem()
	}

	function onAuctionDeleted(msg) {
		if (msg.id !== paramAuctionItemId)
			return

		toastr.error("This auction item has been removed")
	}

	function onBidPlaced(bid) {
		console.log("bidPlaced: ", bid)

		if (!auctionItem || biddings.find(x => x.id === bid.id))
			return

		biddings = [bid, ...(biddings || [])]
	}

	function onJoinAuction() {
		if (!auctionChannel) {
			console.warn("Could not join auction because there is no auction channel available")
			toastr.error("Connection not alive")
			return
		}

		joinAuction(auctionChannel)
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

	function onLeaveAuction() {
		if (!auctionChannel) {
			console.warn("Could not leave auction because there is no auction channel available")
			toastr.error("Connection not alive")
			return
		}

		leaveAuction(auctionChannel)
			.then(result => {
				switch (result) {
					case "removed":
						toastr.success("Auction left!")
						console.log("Auction left")
						auctionItem.user_status = "nothing"
						break

					case "bidding_left":
						toastr.success("Auction is now just followed")
						console.log("Auction is now just followed")
						auctionItem.user_status = "following"
						break

					default:
						toastr.warning("Auction left (unexpected result)")
						console.log("Auction left but result is not known", result)
						auctionItem.user_status = "nothing"
						break
				}
			})
			.catch(error => {
				switch (error) {
					case "already_bidded":
						toastr.error("Could not leave auction because you have already placed bid")
						console.error("Could not leave auction because you have already placed bid")
						break

					case "not_found":
						console.error("Could not leave auction because you are not part of it")
						toastr.error("Could not leave auction because you are not part of it")
						break

					default:
						console.error("Could not leave auction", error)
						toastr.error("Could not leave auction")
						break
				}
			})
	}

	function onPlaceBid({detail: bid}) {
		placeBid(biddingChannel, bid)
			.then(() => {
				toastr.success("Bid place requested", {timeOut: "1000"})
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

	function onToggleFollow() {
		toggleFollow(presenceChannel)
			.then(operation => {
				if (operation === "following") {
					toastr.success("Auction is now followed")
					auctionItem.user_status = operation
				}
				else if (operation === "nothing") {
					toastr.success("Auction is not followed anymore!")
					auctionItem.user_status = operation
				}
				else {
					console.warn("Received unknown result while toggle auction follow status")
					toastr.warning("Received unknown result")
				}
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

	function onAuctionData(auction) {
		auctionItem = auction
	}

	function eventBusListeners(add = false) {
		const fn = add && "on" || "detach"

		const action = (e, callback) =>
			eventBus[fn](e + ":" + paramAuctionItemId, callback)

		action("auction_data", onAuctionData)
		action("bid_placed", onBidPlaced)
		action("bid_placed_success", onPlaceBidSuccess)
		action("place_bid_error", onPlaceBidError)
		// action("user_joined", onUserJoined)
		action("auction_deleted", onAuctionDeleted)
		action("bidding_started", onBiddingStarted)
		action("bidding_ended", onBiddingEnded)
	}

	onMount(() => {
		eventBusListeners(true)
	})

	onDestroy(() => {
		console.log("Destroying auction item")

		auctionChannel && auctionChannel.leave()
		biddingChannel && biddingChannel.leave()
		presenceChannel && presenceChannel.leave()

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
					{auctionOwner}
					on:toggleFollow={onToggleFollow}
					on:deleteAuction={onDeleteAuction}
				/>
			{/if}
		</div>
		<div class="column is-6">
			{#if biddingEnded}
				<Notification>
					This auction has already ended
				</Notification>
			{:else if !biddingStarted}
				<Notification>
					This auction has not started yet
				</Notification>
			{:else if isAuthor}
			{:else if biddingChannel}
				<AuctionItemBiddingForm
					auctionId={auctionItem.id}
					userStatus={auctionItem.user_status}
					minimumBidStep={auctionItem.minimum_bid_step}
					{lastBid}
					on:joinBidding={onJoinAuction}
					on:leaveBidding={onLeaveAuction}
					on:placeBid={onPlaceBid}
				/>
			{:else}
				<Notification>
					Auction connection is not established
				</Notification>
			{/if}

			<AuctionItemBiddings {biddings} />
		</div>
		<div class="column is-2">
			<AuctionItemActiveUsers users={users && $users} />
		</div>
	</div>
</section>
