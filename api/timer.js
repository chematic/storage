export default async function handler(req, res) {
    const targetTimestamp = 1788220800;

    res.setHeader("Content-Type", "application/json");
    res.status(200).json({
        targetTime: targetTimestamp,
        serverTime: Math.floor(Date.now() / 1000)
    });
}
