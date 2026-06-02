export function apiBaseUrl(env: Record<string, string | undefined> = process.env): string {
  return env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8720";
}
