const mongoose = require('mongoose');

// Check if transactions are supported
async function isTransactionSupported() {
  try {
    // In test environment, don't use transactions
    if (process.env.NODE_ENV === 'test') {
      return false;
    }

    const session = await mongoose.startSession();
    await session.endSession();
    return true;
  } catch (error) {
    return false;
  }
}

// Helper function to safely run operations with or without transactions
async function withTransaction(operations) {
  // In test environment or when transactions are not supported,
  // run operations without transaction
  if (process.env.NODE_ENV === 'test') {
    return operations(null);
  }

  const session = await mongoose.startSession();
  let result;

  try {
    const supportsTransactions = await isTransactionSupported();
    
    if (supportsTransactions) {
      session.startTransaction();
      result = await operations(session);
      await session.commitTransaction();
    } else {
      // For standalone MongoDB instances, run operations without transaction
      result = await operations(null);
    }
    return result;
  } catch (error) {
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    throw error;
  } finally {
    await session.endSession();
  }
}

module.exports = {
  isTransactionSupported,
  withTransaction
};
