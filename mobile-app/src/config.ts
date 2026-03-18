// Backend URL from environment variable
// BlueStacks: 10.0.2.2 (routes to host machine)
// Physical device: use your machine's LAN IP
// Localhost: http://localhost:8275
export const BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL || 'http://10.0.2.2:8275';
