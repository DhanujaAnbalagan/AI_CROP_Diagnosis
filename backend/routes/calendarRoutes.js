import express from 'express';
import CalendarTask from '../models/CalendarTask.js';

const router = express.Router();

// Get tasks for a user
router.get('/:userId', async (req, res) => {
    try {
        const tasks = await CalendarTask.find({ user: req.params.userId }).sort({ date: 1 });
        res.json(tasks);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Create a task
router.post('/', async (req, res) => {
    const { userId, title, type, date, notes } = req.body;
    try {
        const task = await CalendarTask.create({
            user: userId,
            title,
            type,
            date,
            notes
        });
        res.status(201).json(task);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Toggle completion status
router.put('/:id/toggle', async (req, res) => {
    try {
        const task = await CalendarTask.findById(req.params.id);
        if (!task) return res.status(404).json({ message: 'Task not found' });

        task.completed = !task.completed;
        const updatedTask = await task.save();
        res.json(updatedTask);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Delete a task
router.delete('/:id', async (req, res) => {
    try {
        const task = await CalendarTask.findById(req.params.id);
        if (!task) return res.status(404).json({ message: 'Task not found' });

        await task.deleteOne();
        res.json({ message: 'Task removed' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

export default router;
