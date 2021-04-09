<script>
	export let title = ""
	export let category = ""
	export let author = ""
	export let description = ""
	export let insertedAt = "Not available"

	function formatDateTime(val) {
		const date = new Date(val)

		return isNaN(date)
			? "Invalid date"
			: date.toLocaleString()
	}

	function getDateString(val) {
		const date = new Date(val)

		return isNaN(date)
			? "Invalid date"
			: date.toISOString().substr(0, 10)
	}
</script>

<div class="card">
	<!--<div class="card-image">
		<figure class="image is-4by3">
			<img src="https://bulma.io/images/placeholders/1280x960.png" alt="Placeholder image">
		</figure>
	</div>-->
	<div class="card-content">
		<div class="media">
			<div class="media-content">
				<p class="title is-4">{title}</p>
				<p class="subtitle is-6">{category}</p>
			</div>
		</div>

		<div class="content">
			<b>Description</b>
			{description}
			<br>
			<b>Inserted at</b>
			<time datetime={getDateString(insertedAt)}>{formatDateTime(insertedAt)}</time>
		</div>
	</div>
</div>
