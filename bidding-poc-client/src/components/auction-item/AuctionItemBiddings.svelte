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
				<td>{itemBid.username}</td>
				<td>{itemBid.amount}</td>
				<td>{m(itemBid.inserted_at).fromNow()}</td>
			</tr>
		{/each}
		</tbody>
	</table>
</Card>
