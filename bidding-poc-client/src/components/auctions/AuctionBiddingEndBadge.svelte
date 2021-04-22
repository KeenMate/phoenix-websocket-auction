<script>
	import moment from "moment"

	export let biddingEnd

	$: minutesRemaining = biddingEnd && moment(biddingEnd).diff(moment(), "minute")
	$: isSoon = minutesRemaining <= 5
	$: someTimeLeft = minutesRemaining > 5 && minutesRemaining < 30
	$: lateEnding = minutesRemaining > 30
</script>

{#if biddingEnd}
	<div
		class="tag"
		class:is-danger={isSoon}
		class:is-warning={someTimeLeft}
		class:is-default={lateEnding}
	>
		{moment(biddingEnd).calendar()} ({moment(biddingEnd).fromNow()})
	</div>
{/if}
