const { Storage } = require('@google-cloud/storage');
const path = require('path');

// Initialize storage
const storage = new Storage({
  keyFilename: path.join(__dirname, '../../service-account-key.json'),
  projectId: process.env.GCP_PROJECT_ID,
});

const bucketName = process.env.GCP_STORAGE_BUCKET || 'city-lifestyle-avatars';
const bucket = storage.bucket(bucketName);

// Configure CORS for the bucket
async function configureBucketCors() {
  await bucket.setCorsConfiguration([
    {
      maxAgeSeconds: 3600,
      method: ['GET', 'PUT', 'POST', 'DELETE'],
      origin: ['*'], // In production, replace with specific origins
      responseHeader: ['Content-Type', 'x-goog-meta-*'],
    },
  ]);
}

// Configure lifecycle management
async function configureBucketLifecycle() {
  await bucket.setMetadata({
    lifecycle: {
      rule: [
        {
          action: { type: 'Delete' },
          condition: {
            age: 30, // Delete objects in tmp folder after 30 days
            matchesPrefix: ['tmp/'],
          },
        },
      ],
    },
  });
}

// Generate signed URL for upload
async function generateUploadUrl(fileName, contentType) {
  const options = {
    version: 'v4',
    action: 'write',
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    contentType,
  };

  const [url] = await bucket.file(fileName).getSignedUrl(options);
  return url;
}

// Generate signed URL for download
async function generateDownloadUrl(fileName) {
  const options = {
    version: 'v4',
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000, // 1 hour
  };

  const [url] = await bucket.file(fileName).getSignedUrl(options);
  return url;
}

// Delete file from storage
async function deleteFile(fileName) {
  await bucket.file(fileName).delete();
}

module.exports = {
  storage,
  bucket,
  configureBucketCors,
  configureBucketLifecycle,
  generateUploadUrl,
  generateDownloadUrl,
  deleteFile,
};
