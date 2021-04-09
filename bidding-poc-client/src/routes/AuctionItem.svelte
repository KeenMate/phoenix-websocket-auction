<script>
	import AuctionItemDetail from "../components/auction/AuctionItemDetail.svelte"
	import AuctionItemBiddings from "../components/auction/AuctionItemBiddings.svelte"
	import Notification from "../components/ui/Notification.svelte"
	import {socket} from "../providers/socket/common"
	import {initAuctionItemChannel} from "../providers/socket/auction-item"

	export let params = {}

	let auctionItemChannel
	let auctionItem = {}
	let users = []
	let biddings = []

	$: paramAuctionItemId = Number(params.id)

	$: $socket && initAuctionItemChannel($socket, paramAuctionItemId, {
		onBidPlaced,
		onUserJoined,
		onAuctionItem: item => auctionItem = item
	})
	.then(({channel, users: usersStore}) => {
		users = usersStore
		auctionItemChannel = channel
	})
	.catch(error => {
		console.error("Could not initiate auction item channel", error)
		toastr.error("Could not open connection for this auction item")
	})

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

		users.update(x => {
			const result = [user, ...x]

			console.log("User joined", result)
			return result // sortBy(result, )
		})
	}
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
		<div class="column is-4">
			{#if !auctionItem}
				<Notification>Loading auction item biddings</Notification>
			{:else}
				<AuctionItemBiddings biddings={auctionItem.biddings} />
			{/if}
		</div>
	</div>
</section>
