const express = require('express');
const router = express.Router();

const farmerdetails = require('../model/farmerdetails');
const buyerdetail = require('../model/buyerdetails');

router.post('/register', async (req, res) => {
  try {
    const { role, name,  phone, location } = req.body;
    
    if (role === 'buyer') {
      const buyer = new buyerdetail({ name,  phone, location }); // Fixed conflict
      await buyer.save();
      res.status(201).json({ message: 'Buyerr registration successful', buyer });
    } else if (role === 'farmer') {
      const farmer = new farmerdetails({ name,  phone, location });
      await farmer.save();
      res.status(201).json({ message: 'Farmer registration successful', farmer });
    } else {
      res.status(400).json({ error: 'Invalid role' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Registration failed', details: err.message });
  }
});

module.exports = router;
