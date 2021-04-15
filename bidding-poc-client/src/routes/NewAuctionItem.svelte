<script>
	import {onMount} from "svelte"
	import {push} from "svelte-spa-router"
	import m from "moment"
	import {getAuctionItemUrl} from "../routes"
	import {createAuction, getAuctionCategories} from "../providers/socket/auction"
	import toastr from "../helpers/toastr-helpers"
	import TextInput from "../components/forms/TextInput.svelte"
	import NumberInput from "../components/forms/NumberInput.svelte"
	import DateInput from "../components/forms/DateInput.svelte"
	import BulmaSelect from "../components/forms/BulmaSelect.svelte"

	let title = ""
	let categoryId = null
	let startPrice = 0
	let biddingEnd = m().add(3, "minute").toDate()
	// minutes
	let postponedFor = null

	let loading = false

	let auctionItemCategories = []

	$: postponedForNumber = postponedFor && Number(postponedFor)
	$: biddingStart = postponedFor && (m().add(postponedForNumber, "seconds")).toDate() || new Date()

	function onSubmit(ev) {
		ev.preventDefault()

		if (!title || !categoryId || !startPrice || startPrice < 0 || biddingEnd < new Date()) {
			toastr.error("Form is filled incorrectly", {timeOut: "5000"})
			return
		}

		loading = true

		// console.log("Create item ", title,
		// 	categoryId,
		// 	startPrice,
		// 	biddingStart,
		// 	biddingEnd)

		createAuction({
			title,
			categoryId,
			startPrice,
			biddingStart,
			biddingEnd
		})
			.then(ctx => {
				push(getAuctionItemUrl(ctx.id))
			})
			.finally(() => {
				loading = false
			})
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
					<BulmaSelect
						value={postponedFor}
						label="Delayed bidding"
						on:change={({detail: d}) => postponedFor = Number(d)}
					>
						<option value="0">No delay</option>
						<option value="20">20 seconds</option>
						<option value="40">40 seconds</option>
						<option value="60">60 seconds</option>
						<option value="80">80 seconds</option>
					</BulmaSelect>
				</div>
				<div class="column is-narrow">
					<DateInput
						value={biddingEnd}
						label="Bidding end"
						required
						on:input={({detail: d}) => biddingEnd = d}
					/>
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
						Start (with delay if you specified one or not)
					</button>
				</div>
			</div>
		</form>
	</div>
</div>
