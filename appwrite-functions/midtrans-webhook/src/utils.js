export function throwIfMissing(value, name) {
  if (!value) {
    throw new Error(`Environment variable ${name} is required but not set`);
  }
}
