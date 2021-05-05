const Production = process.env.SVELTE_APP_PRODUCTION === "true"
const ServerHost = new URL(process.env.SVELTE_APP_SERVER_HOSTNAME)

export const ApiUrl = Production ? "/api" : `${ServerHost.toString()}api`
export const SocketUrl = `ws${Production && "s" || ""}://${ServerHost.host}/socket`
