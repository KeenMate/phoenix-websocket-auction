<script>
	export let lastBid = null
	export let averageBidAmount = null
</script>

<div class="columns is-flex-direction-column">
	<div class="column is-narrow is-flex is-justify-content-center">
		<b class="is-size-3" title="Last bid">
			{lastBid && lastBid.amount || 0}
		</b>
	</div>
	<div class="column is-narrow is-flex is-justify-content-center is-size-6">
		<i title="Average bid">({averageBidAmount || 0})</i>
	</div>
</div>
