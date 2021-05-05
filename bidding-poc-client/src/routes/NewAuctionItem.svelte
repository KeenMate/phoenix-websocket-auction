<script>
	import {onMount} from "svelte"
	import {push} from "svelte-spa-router"
	import m from "moment"
	import {getAuctionItemUrl} from "../routes"
	import {createAuction, getAuctionCategories} from "../providers/socket/auctions"
	import toastr from "../helpers/toastr-helpers"
	import TextInput from "../components/forms/TextInput.svelte"
	import NumberInput from "../components/forms/NumberInput.svelte"
	import DateInput from "../components/forms/DateInput.svelte"
	import BulmaSelect from "../components/forms/BulmaSelect.svelte"

	let title = ""
	let categoryId = null
	let startPrice = 0
	let minimumBidStep = 10
	let biddingEnd = m().add(3, "minute").toDate()
	let postponedFor = null

	let loading = false

	let auctionItemCategories = []

	$: postponedForNumber = postponedFor && Number(postponedFor)
	$: biddingStart = postponedFor && (m().add(postponedForNumber, "seconds")).toDate() || new Date()

	function onSubmit(ev) {
		ev.preventDefault()

		if (!title || !categoryId || startPrice < 0 || biddingEnd < new Date()) {
			toastr.error("Form is filled incorrectly", {timeOut: "5000"})
			return
		}

		loading = true

		createAuction({
			title,
			categoryId,
			startPrice,
			biddingStart,
			biddingEnd,
			minimumBidStep
		})
			.then(ctx => {
				push(getAuctionItemUrl(ctx.id))
			})
			.catch(error => {
				if (error === "id_filled") {
					console.error("Could not create auction because id was filled", error)
					toastr.error("Could not create auction because of inner error")
					return
				}

				if (error === "title_used") {
					console.error("Could not create auction item because title has been used")
					toastr.error("Could not create auction because this title is already being used")
					return
				}

				console.error("Could not create auction item", error)
				toastr.error("Could not create auction")
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
						label="Minimum bid"
						required
						on:input={({detail: d}) => startPrice = d}
					/>
				</div>
				<div class="column is-3">
					<NumberInput
						value={minimumBidStep}
						label="Increment"
						required
						on:input={({detail: d}) => minimumBidStep = d}
					/>
				</div>
			</div>
			<div class="columns">
				<div class="column is-narrow">
					<BulmaSelect
						value={postponedFor}
						label="Delayed start of auction by"
						on:change={({detail: d}) => postponedFor = Number(d)}
					>
						<option value="0">No delay</option>
						<option value="15">15 seconds</option>
						<option value="30">30 seconds</option>
						<option value="45">45 seconds</option>
					</BulmaSelect>
				</div>
				<div class="column is-narrow">
					<DateInput
						value={biddingEnd}
						label="Auction ends at"
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
