import CryptoJS from 'crypto-js';
import dotenv from 'dotenv';

dotenv.config();

const ENC_KEY = process.env.MESSAGE_ENC_KEY;
if (!ENC_KEY || ENC_KEY === 'change-this-key' || ENC_KEY === 'super-secret-message-key-change-me') {
  throw new Error('MESSAGE_ENC_KEY must be set to a strong random value in production');
}

export function encryptMessage(plain) {
  return CryptoJS.AES.encrypt(plain, ENC_KEY).toString();
}

export function decryptMessage(cipher) {
  try {
    const bytes = CryptoJS.AES.decrypt(cipher, ENC_KEY);
    const decrypted = bytes.toString(CryptoJS.enc.Utf8);
    if (!decrypted) {
      throw new Error('Decryption failed - invalid key or corrupted data');
    }
    return decrypted;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Message decryption failed:', error.message);
    return '[Unable to decrypt message]';
  }
}

