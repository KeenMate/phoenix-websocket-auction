<script>
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let placeholder = ""
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
		{#if label}
			<div class="field-label is-normal">
				<label class="label">
					{label}
				</label>
			</div>
		{/if}
		<div class="field-body">
			<div class="field">
				<div class="control">
					<input
						class="input"
						type="number"
						{value}
						{placeholder}
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
				{placeholder}
				{required}
				on:input={onInput}
			>
		</div>
	</div>
{/if}

