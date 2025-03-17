const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const { Octokit } = require('@octokit/rest');
require('dotenv').config();

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN
});

const backupDir = path.join(__dirname, '../backups');
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const backupFileName = `backup-${timestamp}.gz`;
const backupPath = path.join(backupDir, backupFileName);

// Ensure backup directory exists
if (!fs.existsSync(backupDir)) {
  fs.mkdirSync(backupDir);
}

// MongoDB backup command
const mongodbUri = process.env.MONGODB_URI;
const backupCommand = `mongodump --uri="${mongodbUri}" --archive="${backupPath}" --gzip`;

// Execute backup
exec(backupCommand, async (error, stdout, stderr) => {
  if (error) {
    console.error(`Backup failed: ${error}`);
    process.exit(1);
  }

  console.log('Database backup created successfully');

  // Upload to GitHub releases
  try {
    const fileContent = fs.readFileSync(backupPath);
    
    // Create a new release
    const release = await octokit.repos.createRelease({
      owner: process.env.GITHUB_OWNER,
      repo: process.env.GITHUB_REPO,
      tag_name: `backup-${timestamp}`,
      name: `Database Backup ${timestamp}`,
      body: 'Automated database backup',
      draft: false,
      prerelease: false
    });

    // Upload the backup file as a release asset
    await octokit.repos.uploadReleaseAsset({
      owner: process.env.GITHUB_OWNER,
      repo: process.env.GITHUB_REPO,
      release_id: release.data.id,
      name: backupFileName,
      data: fileContent
    });

    console.log('Backup uploaded to GitHub releases successfully');

    // Clean up local backup
    fs.unlinkSync(backupPath);
    console.log('Local backup cleaned up');
  } catch (err) {
    console.error(`GitHub upload failed: ${err}`);
    process.exit(1);
  }
}); 