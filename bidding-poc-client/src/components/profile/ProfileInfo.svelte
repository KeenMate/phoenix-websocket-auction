<script>
	import Card from "../ui/Card.svelte"

	export let user = {}
</script>

<Card>
	{#if user}
		<b>Display name: </b> {user.display_name} <br>
		<b>Username</b> {user.username} <br>
		<b>Is admin: </b> {user.is_admin && "Yes" || "No"} <br>
	{/if}
</Card>
