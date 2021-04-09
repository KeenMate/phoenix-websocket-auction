<script>
	export let biddings = []
</script>

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
			<td>{itemBid.user}</td>
			<td>{itemBid.amount}</td>
			<td>{itemBid.insertedAt.toLocaleString()}</td>
		</tr>
	{/each}
	</tbody>
</table>
