export function stringToNumber(str, defaultValue) {
	const parsed = Number(str)

	return isNaN(parsed)
		? defaultValue
		: parsed
}
