import express from 'express';
import AppSettings from '../models/AppSettings.js';

const router = express.Router();

// @desc    Get user settings
// @route   GET /api/settings/:userId
router.get('/:userId', async (req, res) => {
    try {
        const settings = await AppSettings.findOne({ user: req.params.userId });
        if (settings) {
            res.json(settings);
        } else {
            // Return defaults if not found
            res.json({ language: 'en', audioEnabled: true, guestMode: false });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Update user settings
// @route   POST /api/settings
router.post('/', async (req, res) => {
    const { userId, language, audioEnabled, guestMode } = req.body;

    try {
        let settings = await AppSettings.findOne({ user: userId });

        if (settings) {
            if (language !== undefined) settings.language = language;
            if (audioEnabled !== undefined) settings.audioEnabled = audioEnabled;
            if (guestMode !== undefined) settings.guestMode = guestMode;
            await settings.save();
        } else {
            settings = await AppSettings.create({
                user: userId,
                language,
                audioEnabled,
                guestMode
            });
        }
        res.json(settings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

export default router;
