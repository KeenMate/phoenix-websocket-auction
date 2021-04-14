<script>
	import m from "moment"
	import {getAuctionItemUrl} from "../../routes"
	import Notification from "../ui/Notification.svelte"
	import Card from "../ui/Card.svelte"

	export let auctionItems = []
	export let categories = []
	export let page = 0
	export let pageSize = 10

	$: mappedItems = auctionItems && categories && mapItems()

	function getCategoryTitle(categoryId) {
		return (categories.find(x => x.id === categoryId) || {}).title || "Not available"
	}

	function mapItems() {
		return auctionItems
			.map(x => ({
				...x,
				category: getCategoryTitle(x.category_id)
			}))
	}
</script>

{#if mappedItems && mappedItems.length}
	<Card>
		<table class="table is-fullwidth">
			<thead>
			<tr>
				<th>Title</th>
				<th>Category</th>
				<th>Bidding start</th>
				<th>Inserted at</th>
			</tr>
			</thead>
			<tbody>
			{#each mappedItems as item (item.id)}
				<tr>
					<td>
						<a href="#{getAuctionItemUrl(item.id)}">
							{item.title}
						</a>
					</td>
					<td>{item.category}</td>
					<td style="max-width: 5rem">{m(item.bidding_start).calendar()} ({m(item.bidding_start).fromNow()})</td>
					<td style="max-width: 4rem">{m(item.inserted_at).fromNow()}</td>
				</tr>
			{/each}
			</tbody>
		</table>
	</Card>
{:else}
	<Notification>
		No auction items available
	</Notification>
{/if}
