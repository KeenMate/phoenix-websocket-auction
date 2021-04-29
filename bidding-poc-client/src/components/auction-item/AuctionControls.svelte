<script>
	import {createEventDispatcher} from "svelte"
	import TheButton from "../ui/TheButton.svelte"

	export let user_status = "nothing"

	const dispatch = createEventDispatcher()
</script>

<div class="field is-grouped">
	<p class="control">
		{#if user_status !== "joined"}
			<TheButton on:click={() => dispatch("toggleWatch")}>
				{#if user_status === "following"}
					Unwatch
				{:else if user_status === "nothing"}
					Watch
				{/if}
			</TheButton>
		{/if}
	</p>
	<p class="control">
		<TheButton isDanger on:click={() => dispatch("delete")}>
			Delete
		</TheButton>
	</p>
</div>

<!-- todo: Render `edit` button if user_id is same as owner id -->
