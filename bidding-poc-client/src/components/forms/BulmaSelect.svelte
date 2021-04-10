<script>
	import {createEventDispatcher} from "svelte"

	export let value = null
	export let options = []
	export let label = ""
	export let placeholder = ""
	export let required = false
	export let emptyMessage = ""

	const dispatch = createEventDispatcher()

	function onChange(ev) {
		dispatch("change", ev.target.value)
	}
</script>

<div class="field">
	{#if label}
		<label class="label">{label}</label>
	{/if}
	<div class="control">
		<div class="select">
			<select
				{value}
				{required}
				on:change={onChange}
			>
				{#if placeholder}
					<option>{placeholder}</option>
				{/if}
				{#if $$slots.default}
					<slot />
				{:else}
					{#each options as option}
						<option value={option.value}>
							{option.text}
						</option>
					{/each}
				{/if}
			</select>
		</div>
	</div>
</div>


