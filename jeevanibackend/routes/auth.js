const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

// Define Buyer and Farmer Models
const Buyer = mongoose.model('Buyer', new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true, unique: true },
  location: { type: String, required: true },
  password: { type: String, required: true }, // Added password field
  createdAt: { type: Date, default: Date.now },
}));

const Farmer = mongoose.model('Farmer', new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true, unique: true },
  location: { type: String, required: true },
  password: { type: String, required: true }, // Added password field
  createdAt: { type: Date, default: Date.now },
}));
router.post('/login', async (req, res) => {
  const { role, phone, password } = req.body;

  if (!role || !phone || !password) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const Model = role === 'buyer' ? Buyer : Farmer;

    // Check if user exists
    const user = await Model.findOne({ phone });
    if (!user) {
      return res.status(400).json({ message: 'Invalid phone number or password' });
    }

    // Validate password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid phone number or password' });
    }

    // Return userId along with the role
    res.status(200).json({ 
      message: 'Login successful', 
      role: role,
      userId: user._id.toString() // Add userId to the response
    });
  } catch (error) {
    console.error("🔥 ERROR in /api/login:", error);
    res.status(500).json({ error: error.message });
  }
});
// Register a new user (buyer or farmer)
router.post('/register', async (req, res) => {
  const { role, name, phone, location, password } = req.body;

  if (!role || !name || !phone || !location || !password) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const Model = role === 'buyer' ? Buyer : Farmer;

    // Check if user already exists
    const existingUser = await Model.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash the password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create new user
    const newUser = new Model({
      name,
      phone,
      location,
      password: hashedPassword,
    });

    await newUser.save();
    res.status(201).json({ message: `${role.charAt(0).toUpperCase() + role.slice(1)} registered successfully` });
  } catch (error) {
    console.error("🔥 ERROR in /api/register:", error);
    res.status(500).json({ error: error.message });
  }
});


module.exports = router;