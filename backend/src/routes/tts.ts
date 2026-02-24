import { Router, Request, Response } from 'express';
import OpenAI from 'openai';
import { logger } from '../config/logger';

export const ttsRouter = Router();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// POST /api/tts/speak
ttsRouter.post('/speak', async (req: Request, res: Response) => {
  try {
    const { text, voice = 'nova' } = req.body;
    if (!text || typeof text !== 'string') {
      return res.status(400).json({ error: '텍스트가 필요합니다.' });
    }

    // Limit text length for safety
    const inputText = text.slice(0, 1000);

    const mp3 = await openai.audio.speech.create({
      model: 'tts-1',
      voice: voice,
      input: inputText,
      response_format: 'mp3',
      speed: 0.95,
    });

    const buffer = Buffer.from(await mp3.arrayBuffer());

    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Content-Length', buffer.length.toString());
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.send(buffer);
  } catch (error: any) {
    logger.error('TTS error:', error);

    if (error?.status === 401) {
      return res.status(500).json({ error: 'OpenAI API 키가 설정되지 않았습니다.' });
    }

    res.status(500).json({ error: '음성 생성에 실패했습니다.' });
  }
});
