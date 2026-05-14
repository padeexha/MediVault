const mongoose = require('mongoose');

/**
 * SECURITY: MongoDB Database Connection Configuration
 * - Connects to MongoDB using connection string from environment variable (MONGO_URI)
 * - Never hardcode credentials in source code (use environment variables)
 * - Connection string should include authentication credentials and TLS/SSL encryption
 * - Recommended MONGO_URI format: mongodb+srv://username:password@cluster.mongodb.net/dbname?retryWrites=true&w=majority
 * 
 * Security Best Practices:
 * 1. Credentials Management: Store MONGO_URI in .env file, never commit to version control
 * 2. Network Encryption: Use mongodb+srv for SRV DNS resolution + automatic SSL/TLS
 * 3. Authentication: Include username/password in connection string for DB-level security
 * 4. Authorization: MongoDB enforces role-based access control at database level
 * 5. Connection Pooling: Mongoose manages connection pool for performance
 * 
 * Threat Prevention:
 * 1. Database Breach: Connection string encryption protects credentials in transit
 * 2. Unauthorized Access: Database-level authentication prevents access without credentials
 */
const connectDB = async () => {
  try {
    // Establish MongoDB connection using credentials from environment variable
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`MongoDB connected: ${conn.connection.host}`);
  } catch (error) {
    // Log connection errors and exit process to prevent silent failures
    console.error(`Database connection error: ${error.message}`);
    process.exit(1); // Exit with error code (prevents app startup with broken DB)
  }
};

module.exports = connectDB;