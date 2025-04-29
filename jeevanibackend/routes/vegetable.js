const express = require('express');
const router = express.Router();
const Vegetable = require('../model/vegetables');

// GET all vegetables
router.get('/vegetables', async (req, res) => {
  try {
    const vegetables = await Vegetable.find();
    console.log(`Fetched ${vegetables.length} vegetables:`, vegetables);
    res.status(200).json(vegetables);
  } catch (err) {
    console.error('Error fetching vegetables:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST a new vegetable
router.post('/addvegetable', async (req, res) => {
  try {
    const { name, image } = req.body;
    if (!name || !image) {
      return res.status(400).json({ message: 'Name and image are required' });
    }
    const vegetable = new Vegetable({
      name,
      image,
      createdAt: new Date(),
    });
    await vegetable.save();
    console.log('Vegetable added:', vegetable);
    res.status(201).json({ message: 'Vegetable added successfully', vegetable });
  } catch (err) {
    console.error('Error adding vegetable:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;