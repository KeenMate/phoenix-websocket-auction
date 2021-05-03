/**
 * @description Ordered list of units with their conversion to milliseconds
 */
const timeUnits = [
	{
		unit: "day",
		conversion: 86400000,
		rightDelimiter: " "
	},
	{
		unit: "hour",
		conversion: 3600000,
		rightDelimiter: ":"
	},
	{
		unit: "minute",
		conversion: 60000,
		rightDelimiter: ":"
	},
	{
		unit: "second",
		conversion: 1000,
		rightDelimiter: "."
	}
]

export function formatDuration(milliseconds) {
	const absMilliseconds = milliseconds < 0 && Math.abs(milliseconds) || milliseconds
	const parsed = parseDuration(absMilliseconds)

	return (milliseconds < 0 && "-" || "") + formatParsed(parsed)
}

function formatParsed(parsed) {
	return timeUnits
		.reduce((acc, unit, i, units) => {
			const unitValue = parsed[unit.unit]
			// if (unitValue <= 0 && unit.unit === "day")
			// 	return acc

			const renderRightDelimiter = !!units[i + 1]

			return [
				...acc,
				unitValue.toString().padStart(2, "0"),
				renderRightDelimiter && unit.rightDelimiter
			]
		}, [])
		.filter(x => x)
		.join("")
}

function parseDuration(milliseconds) {
	return timeUnits.reduce((acc, x) => {
		const result = acc.milliseconds / x.conversion

		if (result < 1)
			return acc

		const flooredResult = Math.floor(result)

		return {
			...acc,
			[x.unit]: flooredResult,
			milliseconds: acc.milliseconds - (flooredResult * x.conversion)
		}
	}, {day: 0, hour: 0, minute: 0, second: 0, milliseconds})
}
