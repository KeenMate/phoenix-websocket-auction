<script>
	import {parse, stringify} from "qs"
	import {location, push, querystring} from "svelte-spa-router"
	import {socket} from "../providers/socket/common"
	import {getAuctionCategories, getMyAuctions} from "../providers/socket/auctions"
	import {userStore} from "../providers/auth"
	import {initAuctionBiddingChannel, initAuctionChannel, joinAuction, placeBid} from "../providers/socket/auction"
	import {stringToNumber} from "../helpers/parser"
	import lazyLoader from "../helpers/lazy-loader"
	import eventBus from "../helpers/event-bus"
	import toastr from "../helpers/toastr-helpers"
	import {
		toastAuctionJoined,
		toastBidRequested,
		toastCouldNotJoinAuction,
		toastCouldNotPlaceBid
	} from "../helpers/toastr-messages"
	import Notification from "../components/ui/Notification.svelte"
	import AuctionCategoriesMenu from "../components/auctions/AuctionCategoriesMenu.svelte"
	import AuctionItemsFilters from "../components/auctions/AuctionItemsFilters.svelte"
	import MyAuctionsList from "../components/auctions/MyAuctionsList.svelte"

	let currentAuctions = []
	let auctionsChannels = {}
	let auctionsLoading = false

	let categoriesTask = getAuctionCategories()

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = Number(parsedQuerystring.category || "") || null
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)
	$: auctionItemsTask = getMyAuctions(searchText, selectedCategory, page, pageSize)
		.then(gcExistingAuctionChannels)
		.then(initAuctionChannels)
		.then(storeCurrentAuctions)
		.catch(error => {
			console.error("Could not load my auctions")
			throw error
		})
	$: ownerAuctionsTask = auctionItemsTask && auctionItemsTask.then(filterOwnerAuctions)
	$: joinedAuctionsTask = auctionItemsTask && auctionItemsTask.then(filterJoinedAuctions)
	$: followedAuctionsTask = auctionItemsTask && auctionItemsTask.then(filterFollowedAuctions)
	$: lazyAuctionsTask = auctionItemsTask && lazyLoader(
		auctionItemsTask,
		() => auctionsLoading = true,
		() => auctionsLoading = false
	)

	function storeCurrentAuctions(newAuctions) {
		currentAuctions = newAuctions

		return newAuctions
	}

	function filterOwnerAuctions(auctions) {
		return auctions.filter(auction => auction.user_id === $userStore.id)
	}

	function filterJoinedAuctions(auctions) {
		return auctions.filter(auction => auction.user_status === "joined")
	}

	function filterFollowedAuctions(auctions) {
		return auctions.filter(auction => auction.user_status === "following")
	}

	function gcExistingAuctionChannels(newAuctions) {
		currentAuctions
			.filter(auction => !newAuctions.find(x => x.id === auction.id) && auctionsChannels[auction.id])
			.forEach(auction => {
				Object.values(auctionsChannels[auction.id].channels)
					.forEach(x => x.leave())
				eventBus.off("bid_placed:" + auction.id, auctionsChannels[auction.id].onBidPlaced)

				delete auctionsChannels[auction.id]
			})

		return newAuctions
	}

	function initAuctionChannels(newAuctions) {
		newAuctions
			.filter(x => !auctionsChannels[x.id])
			.forEach(auction => {
				auctionsChannels[auction.id] = {
					channels: {},
					onBidPlaced: bid => onAuctionBidPlaced(auction, bid)
				}

				const auctionJoined = auction.user_status === "joined"
				initAuctionChannel($socket, auction.id, !auctionJoined)
					.then(channel => {
						auctionsChannels[auction.id].channels.auction = channel
					})
				eventBus.on("bid_placed:" + auction.id, auctionsChannels[auction.id].onBidPlaced)

				// init bidding channel for joined auctions
				if (auctionJoined) {
					initAuctionBiddingChannel($socket, auction.id)
						.then(channel => {
							auctionsChannels[auction.id].channels.bidding = channel
						})
				}
			})

		return newAuctions
	}

	function onAuctionBidPlaced(auction, bid) {
		const found = (joinedAuctions.find(x => x.id === auction.id) || followedAuctions.find(x => x.id === auction.id))
		found && (found.last_bid = bid)
	}

	function onSelectCategory({detail: category}) {
		const newPartial = {...parsedQuerystring, category: category && category.id || undefined}

		push(`${$location}?${stringify(newPartial)}`)
	}

	function onUpdateSearchText({detail: search}) {
		push(`${$location}?${stringify({...parsedQuerystring, search})}`)
	}

	function onPlaceBid(auction, amount) {
		const auctionChannels = auctionsChannels[auction.id]
		if (!auctionChannels || !auctionChannels.bidding) {
			console.error("Attempted to place bid for auction that does not have (bidding) channel(s)")
			return
		}

		placeBid(auctionChannels.bidding, amount)
			.then(() => {
				toastBidRequested()
			})
			.catch(error => {
				console.error("Could not place bid", error)
				toastCouldNotPlaceBid()
			})
	}

	function onJoinBidding(auction) {
		const auctionChannels = auctionsChannels[auction.id]
		if (!auctionChannels || !auctionChannels.auction) {
			console.error("Attempted to place bid for auction that does not have channel")
			return
		}

		joinAuction(auctionChannels.auction)
			.then(() => {
				toastAuctionJoined()
				console.log("Auction joined")
				auctionItem.user_status = "joined"

			})
			.catch(error => {
				console.error("Could not join auction", error)
				toastCouldNotJoinAuction()
			})
	}

	function onLeaveBidding(auction) {

	}

</script>

<div class="columns">
	<div class="column is-2">
		<AuctionCategoriesMenu
			{categoriesTask}
			{selectedCategory}
			on:selectCategory={onSelectCategory}
		/>
	</div>
	<div class="column">
		<AuctionItemsFilters
			{searchText}
			on:updateSearchText={onUpdateSearchText}
		/>
		{#await lazyAuctionsTask}
			{#if auctionsLoading}
				<Notification>Loading auction items</Notification>
			{/if}
		{:then _}
			{#await ownerAuctionsTask then ownerAuctions}
				<MyAuctionsList
					title="Your auctions"
					auctions={ownerAuctions}
					on:placeBid={onPlaceBid}
					on:joinBidding={onJoinBidding}
					on:leaveBidding={onLeaveBidding}
				/>
			{/await}
			{#await joinedAuctionsTask then joinedAuctions}
				<MyAuctionsList
					title="Joined auctions"
					auctions={joinedAuctions}
					on:placeBid={onPlaceBid}
					on:joinBidding={onJoinBidding}
					on:leaveBidding={onLeaveBidding}
				/>
			{/await}
			{#await followedAuctionsTask then followedAuctions}
				<MyAuctionsList
					title="Followed auctions"
					auctions={followedAuctions}
					on:placeBid={onPlaceBid}
					on:joinBidding={onJoinBidding}
					on:leaveBidding={onLeaveBidding}
				/>
			{/await}
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load auction items</h4>
		{/await}
	</div>
</div>

