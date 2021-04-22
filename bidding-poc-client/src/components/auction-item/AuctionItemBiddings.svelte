<script>
	import m from "moment"
	import Card from "../ui/Card.svelte"

	export let biddings = []
</script>

<Card>
	<table class="table is-fullwidth">
		<thead>
		<tr>
			<th>Username</th>
			<th>Amount</th>
			<th>Inserted at</th>
		</tr>
		</thead>
		<tbody>
		{#each biddings as itemBid (itemBid.id)}
			<tr>
				<td>{itemBid.user_display_name}</td>
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
