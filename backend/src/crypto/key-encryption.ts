import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

const ALGORITHM = "aes-256-gcm";
const IV_LENGTH = 12;
const AUTH_TAG_LENGTH = 16;
const KEY_VERSION = 1;

export interface EncryptedKey {
  v: number;
  iv: string;
  data: string;
  tag: string;
}

export class KeyEncryption {
  private readonly encryptionKey: Buffer;

  constructor(encryptionKeyB64: string) {
    this.encryptionKey = Buffer.from(encryptionKeyB64, "base64");
    if (this.encryptionKey.length !== 32) {
      throw new Error(`BYOK_ENCRYPTION_KEY must be 32 bytes (base64-encoded), got ${this.encryptionKey.length} bytes`);
    }
  }

  encrypt(plaintext: string): string {
    const iv = randomBytes(IV_LENGTH);
    const cipher = createCipheriv(ALGORITHM, this.encryptionKey, iv, { authTagLength: AUTH_TAG_LENGTH });
    let encrypted = cipher.update(plaintext, "utf8", "base64url");
    encrypted += cipher.final("base64url");
    const tag = cipher.getAuthTag();
    const payload: EncryptedKey = {
      v: KEY_VERSION,
      iv: iv.toString("base64url"),
      data: encrypted,
      tag: tag.toString("base64url")
    };
    return JSON.stringify(payload);
  }

  decrypt(ciphertext: string): string {
    const payload: EncryptedKey = JSON.parse(ciphertext);
    if (payload.v !== KEY_VERSION) {
      throw new Error(`Unsupported BYOK key version: ${payload.v}`);
    }
    const iv = Buffer.from(payload.iv, "base64url");
    const tag = Buffer.from(payload.tag, "base64url");
    const decipher = createDecipheriv(ALGORITHM, this.encryptionKey, iv, { authTagLength: AUTH_TAG_LENGTH });
    decipher.setAuthTag(tag);
    let decrypted = decipher.update(payload.data, "base64url", "utf8");
    decrypted += decipher.final("utf8");
    return decrypted;
  }
}