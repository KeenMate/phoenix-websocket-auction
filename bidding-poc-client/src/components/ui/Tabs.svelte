<script>
	export let isNavbar = false
</script>

<div class="tabs {isNavbar && 'mb-0 is-right' || ''}">
	<ul>
		<slot />
	</ul>
</div>

<style lang="sass">
	.tabs.is-right
		ul
			border-bottom: none !important
</style>
