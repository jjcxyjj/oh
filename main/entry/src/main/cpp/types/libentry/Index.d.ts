export interface RenderReport {
  paths: string[];
  labels: string[];
  elapsedMs: number;
}
export const run: (inputA: string, inputB: string, outputPrefix: string,
  mode: number, preset: number, gainA: number, gainB: number) => Promise<RenderReport>;
