# 🎧 AWS Audio Transcription Automation with CloudFormation

Welcome to the **AWS Audio Transcription Automation** project! This CloudFormation stack automates transcription of audio files (MP4, MP3, and WAV) using **Amazon Transcribe**. Easily upload your audio files to S3, trigger transcription jobs, and store results in an output S3 bucket — all automated! 🎉

## 🚀 Features
- **Automatic Transcription**: Supports MP4, MP3, and WAV audio files, using Amazon Transcribe.
- **Secure Storage**: AES-256 encryption for S3 buckets.
- **Lifecycle Management**: Automatically expire input files after 1 day and log files after 2 days.
- **Logging**: Logs Lambda function execution and S3 access.
- **Event-Driven Transcription**: Automatically triggers transcription jobs upon file upload.

## 🛠️ Technology Stack
- **Amazon S3**: Storage for audio files, transcription results, and access logs.
- **AWS Lambda**: Event-driven function to trigger transcription jobs.
- **Amazon Transcribe**: Speech-to-text transcription service.
- **Amazon CloudWatch**: Logs Lambda function activity.
- **IAM Roles**: Manages permissions for Lambda and S3.

## 🎯 How It Works
1. **Upload** audio files (MP4, MP3, or WAV) to the designated S3 input bucket.
2. **Lambda Triggered**: Upon upload, a Lambda function triggers an Amazon Transcribe job.
3. **Transcription Results**: Transcription results are stored in the specified S3 output bucket.

## 🧩 CloudFormation Resources
This CloudFormation stack provisions the following resources:
- **Input S3 Bucket**: For audio files awaiting transcription.
- **Output S3 Bucket**: Stores completed transcription results.
- **Logging S3 Bucket**: Logs access events for both input and output buckets.
- **AWS Lambda Function**: Automatically triggers transcription jobs.
- **IAM Role**: Provides necessary permissions for the Lambda function.
- **CloudWatch Log Group**: Logs Lambda function execution.

## 📦 Installation & Setup

### Prerequisites
1. **AWS CLI**: Installed and configured on your local machine.
2. **AWS Account**: Ensure permissions to create CloudFormation stacks, Lambda functions, and S3 buckets.
3. **Edit Deploy File**: Edit the `STACK_NAME` constant to a unique name in the `deploy-transcription.sh` file. and also the region in the `s3-trigger.sh` file if not us-east-1.

### Deploy the Stack
1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/audio-transcription-automation.git
   cd audio-transcription-automation
   ```

2. **Run the deployment script**:
   ```bash
   ./bin/deploy-transcription.sh
   ```
   
   This script deploys the CloudFormation stack using a template file, setting up the required S3 buckets, Lambda function, and permissions.

3. **Deploy S3 Trigger for Lambda**:
   After deploying the CloudFormation stack, set up the S3 bucket trigger using `s3-trigger.sh`:
   ```bash
   ./bin/s3-trigger.sh
   ```
   4. **Upload Audio File to S3**:
   After running the S3 bucket trigger uploaod your files to s3 using `upload-to-s3.sh` Edit the file variables with your info.
   ```bash
   ./bin/upload-to-s3.sh
   ```

   > **Note**: The S3 trigger configuration script (`s3-trigger.sh`) is created as a separate script to avoid circular dependencies between the S3 bucket, Lambda function, and logging configuration.

4. **Verify Deployment**: Monitor the deployment progress in the **AWS CloudFormation Console** to ensure all resources are created successfully.

5. **Start Transcribing**: Once deployed, simply upload audio files to the designated input S3 bucket to start transcription.

> **Note on Output**: Transcription output files are stored in JSON format in the output S3 bucket. For now, the text needs to be manually copied from the JSON files until the feature update is complete.

## 📂 Project Structure

```bash
.
├── audio-samples        # 3 sample audio files in mp3, mp4, and wav format
├── bin/
│   ├── deploy-transcription.sh # Deployment script
│   ├── s3-trigger.sh           # Lambda role configuration and S3 bucket notifications
    ├── upload-to-s3.sh           # Upload selected audio file to s3
├── cfn/transcribe.yaml        # CloudFormation template
├── README.md                   # Project documentation
```

## 📊 Monitoring & Logging
- **CloudWatch Logs**: View Lambda execution logs in the AWS CloudWatch console.
- **S3 Access Logs**: Access logs for input and output S3 buckets are stored in the logging bucket.

## ⚙️ Recommended Practices
- **Adjust Bucket Retention**: Modify lifecycle policies to suit your data retention requirements.
- **Configure Notifications**: Install and configure `notify-send` on Linux for deployment notifications (optional).
- **Review IAM Policies**: Ensure permissions are as restrictive as possible for production use.

## 🤝 Contributing
We welcome contributions! To contribute, follow these steps:

### How to Contribute
1. Fork the repo 🍴
2. Create a new branch:
   ```bash
   git checkout -b feature/awesome-feature
   ```
3. Commit your changes 💻
4. Push your branch and submit a PR 🛠️

## 🌍 License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🏆 Acknowledgements
- Thanks to **AWS** for their robust services. 💪
- Special thanks to **OpenAI** for inspiring innovation with AI-based projects. 🙌

## 📬 Contact

Warner Bell - [Tap In!](https://dot.cards/warnerbell)


## 💚 Enjoyed this project? Help keep them coming!

If you'd like to support future projects, consider contributing:

[![Cash App](https://img.shields.io/badge/Cash_App-$dedprez20-00C244?style=flat&logo=cash-app)](https://cash.app/$dedprez20)

Thanks a ton for your generosity!  
Your Super Cool Cloud Builder - **Warner Bell**

---

✨ **Happy Transcribing!** ✨
