<script>
	export let navExpanded = false
</script>

<a
	class="navbar-burger"
	class:is-active={navExpanded}
	role="button"
	aria-label="menu"
	aria-expanded="false"
	on:click
>
	<span aria-hidden="true"></span>
	<span aria-hidden="true"></span>
	<span aria-hidden="true"></span>
</a>
