<script>
	export let isPrimary = false
	export let isInfo = false
	export let isLink = false
	export let isDanger = false
	export let isWarning = false
	export let isSuccess = false
	export let type = "button"
</script>

<button
	class="button"
	class:is-primary={isPrimary}
	class:is-info={isInfo}
	class:is-link={isLink}
	class:is-danger={isDanger}
	class:is-warning={isWarning}
	class:is-success={isSuccess}
	{type}
	on:click
>
	<slot />
</button>
