<script>
	import {onDestroy} from "svelte"
	import m from "moment"
	import toastr from "../helpers/toastr-helpers"
	import {socket} from "../providers/socket/common"
	import {initBiddingChannel, joinBidding, placeBid} from "../providers/socket/bidding"
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

	$: $socket && initBiddingChannel($socket, paramAuctionItemId, {
		onBidPlaced,
		onUserJoined,
		onAuctionItem: item => auctionItem = item,
		onBiddings: payload => biddings = payload.biddings
	})
		.then(({channel, users: usersStore}) => {
			users = usersStore
			auctionItemChannel = channel
		})
		.catch(error => {
			console.error("Could not initiate auction item channel", error)
			toastr.error("Could not open connection for this auction item")
		})

	$: noBidding = m(auctionItem.bidding_start).isAfter() || m(auctionItem.bidding_end).isBefore()

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

		// users.update(x => {
		// 	const result = [user, ...x]
		//
		// 	console.log("User joined", result)
		// 	return result // sortBy(result, )
		// })
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

	function onPlaceBid({detail: bid}) {
		placeBid(auctionItemChannel, bid)
			.then(newBid => {
				toastr.success("Bid placed!", {timeOut: "2000"})
				onBidPlaced(newBid)
			})
			.catch(error => {
				console.error("Could not place bid", error)
				toastr.error("Could not place bid", {timeOut: "5000"})
			})
	}

	onDestroy(() => {
		if (auctionItemChannel)
			// todo: check if user is joined (in that case leave channel open - it should be stored globally elsewhere)
			auctionItemChannel.leave()
	})
</script>

<section class="auction-item">
	<div class="columns is-centered">
		<div class="column is-4">
			{#if !auctionItem}
				<Notification>Loading auction item</Notification>
			{:else}
				<AuctionItemDetail {...auctionItem} />
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
					on:placeBid={onPlaceBid}
				/>
			{/if}

			<AuctionItemBiddings {biddings} />
		</div>
		<div class="column is-2">
			<AuctionItemActiveUsers users={users && $users} />
		</div>
	</div>
</section>
