<script>
	import m from "moment"
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let value = new Date()
	export let required = false

	const dispatch = createEventDispatcher()

	function onInput(ev) {
		dispatch("input", new Date(ev.target.value))
	}
</script>

<div class="field">
	<label class="label">
		{label}
	</label>
	<div class="control">
		<input
			class="input"
			type="datetime-local"
			value={m(value).format("yyyy-MM-DDTHH:mm")}
			{required}
			on:input={onInput}
		>
	</div>
</div>
