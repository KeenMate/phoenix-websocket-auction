<script>
	export let isSmall = false
</script>

<section
	class="hero"
	class:is-small={isSmall}
>
	<div class="hero-body">
		<p class="title">
			<slot />
		</p>
		{#if $$slots.subtitle}
			<p class="subtitle">
				<slot name="subtitle" />
			</p>
		{/if}
	</div>
</section>
