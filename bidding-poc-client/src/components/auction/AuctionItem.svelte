<script>
	export let title = ""
	export let insertedAt = null
</script>

<div class="card">
	<div class="card-content">
		<div class="media">
			<div class="media-left">
				<i class="fas fa-box-open"></i>
			</div>
			<div class="media-content">
				<p class="title is-4">{title}</p>
			</div>
		</div>

		<div class="content">
			{#if insertedAt}
				<time datetime={insertedAt.toISOString()}>{insertedAt.toLocaleString()}</time>
			{/if}
		</div>
	</div>
</div>
