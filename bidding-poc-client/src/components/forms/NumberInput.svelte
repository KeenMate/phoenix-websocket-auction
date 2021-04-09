<script>
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let value = 0
	export let required = false

	const dispatch = createEventDispatcher()

	function onInput(ev) {
		dispatch("input", Number(ev.target.value))
	}

</script>

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
