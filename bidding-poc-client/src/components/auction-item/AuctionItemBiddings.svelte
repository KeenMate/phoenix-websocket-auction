<script>
	import m from "moment"
	import Card from "../ui/Card.svelte"
	import UserLink from "./UserLink.svelte"

	export let biddings = []
</script>

<Card>
	<table class="table is-fullwidth">
		<thead>
		<tr>
			<th>Bidder</th>
			<th>Amount</th>
			<th>Bidded</th>
		</tr>
		</thead>
		<tbody>
		{#each biddings as itemBid (itemBid.id)}
			<tr>
				<td>
					<UserLink user={{id: itemBid.user_id, display_name: itemBid.user_display_name}} />
				</td>
				<td>{itemBid.amount}</td>
				<td>{m(itemBid.inserted_at).fromNow()}</td>
			</tr>
		{/each}
		</tbody>
	</table>
</Card>

<style lang="sass">
	table.table
		thead
			tr
				display: flex

				th
					flex: 1

			tr
				width: 100%

		tbody
			display: block
			overflow-y: auto
			max-height: calc(100vh - 14rem)

			tr
				display: flex

				td
					flex: 1
</style>
