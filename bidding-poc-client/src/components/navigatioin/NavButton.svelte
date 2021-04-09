<script>
	export let link = ""
</script>

<a class="navbar-item" href="{link && `#${link}` || 'javascript:void(0);'}">
	<slot />
</a>
