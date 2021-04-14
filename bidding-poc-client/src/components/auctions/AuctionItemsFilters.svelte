<script>
	import {createEventDispatcher} from "svelte"
	import {debounce} from "lodash"
	import {debounceDelay} from "../../constants/ui"
	import TextInput from "../forms/TextInput.svelte"

	export let searchText = ""

	const dispatch = createEventDispatcher()

	const onSearchTextInput = debounce(ev => {
		dispatch("updateSearchText", ev.detail)
	}, debounceDelay)

</script>

	<section class="auction-item-filters mb-2">
		<TextInput label="Search auctions" value={searchText} on:input={onSearchTextInput} />
	</section>
