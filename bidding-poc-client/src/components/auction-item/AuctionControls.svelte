<script>
	import {createEventDispatcher} from "svelte"
	import TheButton from "../ui/TheButton.svelte"

	export let userStatus = "nothing"
	export let isAuthor = false

	const dispatch = createEventDispatcher()
</script>

<div class="field is-grouped is-justify-content-flex-end">
	{#if userStatus !== "joined"}
		<p class="control">
			<TheButton on:click={() => dispatch("toggleFollow")}>
				{#if userStatus === "following"}
					UnFollow
				{:else if userStatus === "nothing"}
					Follow
				{/if}
			</TheButton>
		</p>
	{/if}
	{#if isAuthor}
		<p class="control">
			<!-- todo: Render `edit` button -->
			<TheButton isDanger on:click={() => dispatch("delete")}>
				Delete
			</TheButton>
		</p>
	{/if}
</div>
