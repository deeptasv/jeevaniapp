const mongoose = require('mongoose');

const farmerVegetableSchema = new mongoose.Schema({
  farmerId: {
    type: String,
    required: true,
  },
  vegetableId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vegetable',
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    default: 0,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('FarmerVegetable', farmerVegetableSchema);