export function sortBy(array, selector) {
	array.sort(function (l, r) {
		const nameA = String(selector(l)).toUpperCase() // ignore upper and lowercase
		const nameB = String(selector(r)).toUpperCase() // ignore upper and lowercase
		if (nameA < nameB) {
			return -1
		}
		if (nameA > nameB) {
			return 1
		}

		// names must be equal
		return 0
	})

	return array
}
