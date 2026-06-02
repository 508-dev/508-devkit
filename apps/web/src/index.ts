export function apiBaseUrl(env: Record<string, string | undefined> = import.meta.env): string {
  return env.VITE_API_BASE_URL ?? "http://127.0.0.1:8720";
}
