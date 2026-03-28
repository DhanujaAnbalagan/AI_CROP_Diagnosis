import mongoose from 'mongoose';

const appSettingsSchema = mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'User'
    },
    language: {
        type: String,
        default: 'en' // 'en', 'hi', 'te', etc.
    },
    audioEnabled: {
        type: Boolean,
        default: true
    },
    guestMode: {
        type: Boolean,
        default: false
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

const AppSettings = mongoose.model('AppSettings', appSettingsSchema);

export default AppSettings;
