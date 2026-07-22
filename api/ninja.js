export default async function handler(req, res) {
    if (req.headers.auth !== "azuontop") {
        return res.status(403).send("Forbidden")
    }

    const response = await fetch(
        "https://raw.githubusercontent.com/chematic/storage/main/api/v1/ninjatycoonhub.luau"
    )

    const script = await response.text()

    res.setHeader("Content-Type", "text/plain")
    res.send(script)
}
