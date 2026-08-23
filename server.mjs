import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import multer from 'multer';

const app = express();
const upload = multer({ dest: 'uploads/' });
app.use(cors());
app.get('/health', (_req, res) => res.json({ ok: true, service: 'AVPlayer AI' }));

app.post('/subtitle', upload.single('media'), async (req, res) => {
  // AI provider integration is intentionally left server-side.
  // Add your speech-to-text + Indonesian translation provider here.
  if (!req.file) return res.status(400).json({ error: 'media is required' });
  return res.json({
    subtitle: '',
    message: 'Backend foundation is ready. Configure your AI speech-to-text provider.'
  });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`AVPlayer AI backend listening on ${port}`));
