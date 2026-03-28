import mongoose from 'mongoose';

const cropPreferenceSchema = mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'User'
    },
    selectedCrops: [{
        type: String // e.g., 'Wheat', 'Rice', 'Maize'
    }],
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

const CropPreference = mongoose.model('CropPreference', cropPreferenceSchema);

export default CropPreference;
