<script>
	export let type = "default"
</script>

{#if type === "default"}
	<i class="fas fa-info-circle"></i>
{:else if type === "error"}
	<i class="fas fa-bug"></i>
{:else if type === "warning"}
	<i class="fas fa-exclamation-triangle"></i>
{:else if type === "success"}
	<i class="fas fa-check"></i>
{:else if type === "info"}
	<i class="fas fa-info-circle"></i>
{/if}
