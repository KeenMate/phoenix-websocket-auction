/**
 * @description Ordered list of units with their conversion to milliseconds
 */
const timeUnits = [
	{
		unit: "day",
		unitSuffix: "d",
		conversion: 86400000,
		rightDelimiter: " "
	},
	{
		unit: "hour",
		unitSuffix: "h",
		conversion: 3600000,
		rightDelimiter: ":"
	},
	{
		unit: "minute",
		unitSuffix: "m",
		conversion: 60000,
		rightDelimiter: ":"
	},
	{
		unit: "second",
		unitSuffix: "s",
		conversion: 1000,
		rightDelimiter: "."
	}
]

export function toCountdown(milliseconds) {
	const absMilliseconds = milliseconds < 0 && Math.abs(milliseconds) || milliseconds
	const parsed = parseDuration(absMilliseconds)
	
	return timeUnits
		.map(unit => {
			if (!parsed[unit.unit])
				return ""
			return parsed[unit.unit] + unit.unitSuffix
		})
}

export function formatCounterDuration(milliseconds) {
	const absMilliseconds = milliseconds < 0 && Math.abs(milliseconds) || milliseconds
	const parsed = parseDuration(absMilliseconds)

	return (milliseconds < 0 && "-" || "") + formatCounterParsed(parsed)
}

function formatCounterParsed(parsed) {
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
