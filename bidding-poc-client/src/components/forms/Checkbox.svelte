<script>
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let checked = false

	const dispatch = createEventDispatcher()

	function onChange(ev) {
		ev.preventDefault()
		dispatch("change", ev.target.checked)
	}

</script>

<label class="checkbox">
	<input
		type="checkbox"
		{checked}
		on:change={onChange}
	>
	{label}
</label>
