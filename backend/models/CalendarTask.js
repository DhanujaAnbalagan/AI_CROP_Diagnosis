import mongoose from 'mongoose';

const calendarTaskSchema = mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    title: {
        type: String,
        required: true
    },
    type: {
        type: String,
        enum: ['watering', 'fertilizer', 'pesticide', 'harvest', 'other'],
        default: 'other'
    },
    date: {
        type: Date,
        required: true
    },
    completed: {
        type: Boolean,
        default: false
    },
    notes: {
        type: String,
        default: ''
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

const CalendarTask = mongoose.model('CalendarTask', calendarTaskSchema);

export default CalendarTask;
