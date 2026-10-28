import CryptoJS from 'crypto-js';
import dotenv from 'dotenv';

dotenv.config();

const ENC_KEY = process.env.MESSAGE_ENC_KEY || 'change-this-key';

export function encryptMessage(plain) {
  return CryptoJS.AES.encrypt(plain, ENC_KEY).toString();
}

export function decryptMessage(cipher) {
  try {
    const bytes = CryptoJS.AES.decrypt(cipher, ENC_KEY);
    return bytes.toString(CryptoJS.enc.Utf8);
  } catch {
    return '';
  }
}

