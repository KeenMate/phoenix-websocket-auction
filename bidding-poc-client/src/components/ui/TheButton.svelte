<script>
	export let isPrimary = false
	export let isInfo = false
	export let isLink = false
	export let isDanger = false
	export let isWarning = false
	export let isSuccess = false
</script>

<button
	class="button"
	class:is-primary={isPrimary}
	class:is-info={isInfo}
	class:is-link={isLink}
	class:is-danger={isDanger}
	class:is-warning={isWarning}
	class:is-success={isSuccess}
	on:click
>
	<slot />
</button>
