<script>
	import {getAuctionItemUrl} from "../../routes"
	import Notification from "../ui/Notification.svelte"

	export let auctionItems = []
	export let page = 0
	export let pageSize = 10
</script>

{#if auctionItems && auctionItems.length}
	<table class="table is-fullwidth">
		<thead>
		<tr>
			<th>Title</th>
			<th>Category</th>
			<th>Inserted at</th>
		</tr>
		</thead>
		<tbody>
		{#each auctionItems as item (item.id)}
			<tr>
				<td>
					<a href="#{getAuctionItemUrl(item.id)}">
						{item.title}
					</a>
				</td>
				<td>{item.category}</td>
				<td>{item.inserted_at}</td>
			</tr>
		{/each}
		</tbody>
	</table>
{:else}
	<Notification>
		No auction items available
	</Notification>
{/if}
