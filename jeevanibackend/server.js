const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRoutes = require('./routes/auth'); // Import auth routes
const vegetableRoutes = require('./routes/vegetable');
// Initialize Express
const app = express();
app.use(express.json());
app.use(cors());

// Connect to MongoDB
mongoose.connect('mongodb+srv://parvathyysalin:itsme@jeevanicluster.foovzgn.mongodb.net/jeevaniDB?retryWrites=true&w=majority&appName=JeevaniCluster', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('MongoDB Connected'))
  .catch(err => console.log('MongoDB Connection Error:', err));

// Use Routes
app.use('/api', authRoutes);
app.use('/api', vegetableRoutes);
// Start Server
const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});