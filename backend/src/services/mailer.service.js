const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.example.com',
  port: process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : 587,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
  },
});

async function sendMail({ to, subject, text, html }) {
  const from = process.env.SMTP_FROM || 'no-reply@vallexpress.local';
  const info = await transporter.sendMail({ from, to, subject, text, html });
  return info;
}

async function sendPasswordResetCode(email, code) {
  const subject = 'ValleXpress - Código de recuperación de contraseña';
  const text = `Tu código de recuperación es: ${code}. Tiene 10 minutos de validez.`;
  const html = `<p>Tu código de recuperación es: <b>${code}</b></p><p>Tiene 10 minutos de validez.</p>`;
  return sendMail({ to: email, subject, text, html });
}

module.exports = { sendMail, sendPasswordResetCode };
