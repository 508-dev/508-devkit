export function apiBaseUrl(env: Record<string, string | undefined> = {}): string {
  return env.WEB_API_BASE_URL ?? "http://127.0.0.1:8720";
}
