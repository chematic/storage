export default async function handler(req, res) {
    const targetTimestamp = 1785271408;

    res.setHeader("Content-Type", "application/json");
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.status(200).json({
        targetTime: targetTimestamp,
        serverTime: Math.floor(Date.now() / 1000)
    });
}
