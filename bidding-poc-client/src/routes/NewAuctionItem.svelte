<script>
	import {auctionChannel, createAuction, getAuctionCategories} from "../providers/socket/auction"
	import TextInput from "../components/forms/TextInput.svelte"
	import NumberInput from "../components/forms/NumberInput.svelte"
	import DateInput from "../components/forms/DateInput.svelte"
	import BulmaSelect from "../components/forms/BulmaSelect.svelte"
	import {onMount} from "svelte"

	let title = ""
	let categoryId = null
	let startPrice = 0
	let biddingEnd = new Date()
	// minutes
	let postponedFor = null

	let loading = false

	let auctionItemCategories = []

	function onSubmit(ev) {
		ev.preventDefault()

		if (!title || !categoryId || !startPrice || startPrice < 0 || biddingEnd < new Date()) {
			alert("Form is filled incorrectly")
			return
		}

		loading = true
		createAuction({
			title,
			categoryId,
			startPrice,
			biddingEnd
		})
			.then(ctx => {
				// todo: change route to auction edit
			})
			.finally(() => {
				loading = false
			})

		// rest way
		// creationTask = createAuctionItem(title, category, startPrice, biddingEnd)
		// 	.finally(() => {
		// 		loading = false
		// 	})
	}

	onMount(() => {
		getAuctionCategories()
		.then(categories => {
			auctionItemCategories = categories
			.map(x => ({
				value: x.id,
				text: x.title
			}))
		})
		.catch(error => {
			console.error("Could not get auction categories", error)
			toastr.error("Could not load auction categories")
		})
	})
</script>

<div class="columns is-centered">
	<div class="column is-half">
		<form class="new-auction-item" on:submit={onSubmit}>
			<TextInput
				value={title}
				label="Title"
				required
				on:input={({detail: d}) => title = d}
			/>
			<div class="columns">
				<div class="column is-narrow">
					<BulmaSelect
						value={categoryId}
						options={auctionItemCategories}
						label="Category"
						placeholder="Select category"
						emptyMessage="No items available"
						required
						on:change={({detail: d}) => categoryId = Number(d)}
					/>
				</div>
				<div class="column is-3">
					<NumberInput
						value={startPrice}
						label="Starting price"
						required
						on:input={({detail: d}) => startPrice = d}
					/>
				</div>
			</div>
			<div class="columns">
				<div class="column is-narrow">
					<DateInput
						value={biddingEnd}
						label="Bidding end"
						required
						on:input={({detail: d}) => biddingEnd = d}
					/>
				</div>
				<div class="column is-narrow">
					<BulmaSelect
						value={postponedFor}
						label="Delayed bidding"
						placeholder="Select postpone duration"
						on:change={({detail: d}) => postponedFor = Number(d)}
					>
						<option value="0">No delay</option>
						<option value="10">10 minutes</option>
						<option value="30">30 minutes</option>
						<option value="60">1 hour</option>
					</BulmaSelect>
				</div>
			</div>
			<div class="level">
				<div class="level-left"></div>
				<div class="level-right">
					<button
						class="button is-primary"
						type="submit"
						disabled={loading}
					>
						Create
					</button>
				</div>
			</div>
		</form>
	</div>
</div>
