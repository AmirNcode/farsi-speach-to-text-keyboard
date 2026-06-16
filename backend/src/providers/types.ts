export interface TranscriptionResult {
  text: string;
  language: string;
}

export interface TranscriptionProvider {
  transcribe(audio: Blob, languageHint?: string): Promise<TranscriptionResult>;
}

export class ProviderError extends Error {}
