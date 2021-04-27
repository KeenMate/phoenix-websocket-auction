<script>
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let value = 0
	export let required = false
	export let isHorizontal = false

	const dispatch = createEventDispatcher()

	function onInput(ev) {
		dispatch("input", Number(ev.target.value))
	}

</script>

{#if isHorizontal}
	<div class="field is-horizontal">
		<div class="field-label is-normal">
			<label class="label">
				{label}
			</label>
		</div>
		<div class="field-body">
			<div class="field">
				<div class="control">
					<input
						class="input"
						type="number"
						{value}
						{required}
						on:focus
						on:blur
						on:input={onInput}
					>
				</div>
			</div>
		</div>
	</div>
{:else}
	<div class="field">
		<label class="label">
			{label}
		</label>
		<div class="control">
			<input
				class="input"
				type="number"
				{value}
				{required}
				on:input={onInput}
			>
		</div>
	</div>
{/if}

