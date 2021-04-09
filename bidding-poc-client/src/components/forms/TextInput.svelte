<script>
	import {createEventDispatcher} from "svelte"

	export let label = ""
	export let value = ""
	export let required = false
	export let isPassword = false

	const dispatch = createEventDispatcher()

	function onInput(ev) {
		dispatch("input", ev.target.value)
	}

</script>

<div class="field">
  <label class="label">
		{label}
	</label>
  <div class="control">
    <input
			class="input"
			type={isPassword && "password" || "text"}
			value={value}
	    {required}
			on:input={onInput}
		>
  </div>
</div>
