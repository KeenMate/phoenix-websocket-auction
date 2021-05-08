<script>
	export let biddingEndCountdown = []
</script>

{#if biddingEndCountdown.length}
	<div class="columns is-flex-direction-column">
		<div class="column is-flex is-justify-content-center">
			<b class="is-size-3">{biddingEndCountdown[0]}</b>
		</div>
		<div class="column">
			<div class="columns is-justify-content-center">
				<div class="column is-narrow">
					{#if biddingEndCountdown.length > 1}
						<span class="is-size-5 is-block has-text-centered">
							{biddingEndCountdown[1]}
						</span>
					{/if}
				</div>
				<div class="column is-narrow">
					{#if biddingEndCountdown.length > 2}
						<span class="is-size-5">
							{biddingEndCountdown[2]}
						</span>
					{/if}
				</div>
			</div>
		</div>
	</div>
{/if}
