<script>
	import Card from "../ui/Card.svelte"

	export let user = {}
</script>

<Card>
	{#if user}
		<b>Username: </b> {user.display_name} <br>
		<b>Is admin: </b> {user.is_admin && "Yes" || "No"} <br>
	{/if}
</Card>
