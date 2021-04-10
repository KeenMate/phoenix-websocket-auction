<script>
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let value = new Date()
	export let required = false

	const dispatch = createEventDispatcher()

	function onInput(ev) {
		dispatch("input", new Date(ev.target.value))
	}

	function formatDate(val) {
		if (!val)
			return ""

		const year = val.getFullYear()
		const month = val.getMonth()
		const day = val.getDay()
		const hours = val.getHours()
		const minutes = val.getMinutes()
		// const seconds = val.getSeconds()

		return `${padNumber(year, 4)}-${padNumber(month, 2)}-${padNumber(day, 2)}T${padNumber(hours, 2)}:${padNumber(minutes, 2)}`
	}

	function padNumber(number, padding) {
		return number.toString().padStart(padding, "0")
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
			value={formatDate(value)}
			{required}
			on:input={onInput}
		>
	</div>
</div>
