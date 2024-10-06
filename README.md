# 🎧 AWS Audio Transcription Automation with CloudFormation

Welcome to the **AWS Audio Transcription Automation** project! This CloudFormation stack automates the transcription of audio files (MP4, MP3, and WAV) using **Amazon Transcribe**. Easily upload your audio files to S3, trigger transcription jobs, and get your results stored in another S3 bucket — all automated! 🎉

## 🚀 Features
- **Automatic Transcription** of MP4, MP3, and WAV audio files with Amazon Transcribe
- **Secure Storage** using AES-256 encryption for S3 buckets
- **Lifecycle Management**: Automatically expire input files after 1 day and log files after 7 days
- **Automatic Logging** of Lambda function execution and S3 access
- **Lambda Triggers** based on file creation in S3, ensuring fast and responsive transcriptions

## 🎯 How It Works
1. **Upload** audio files (MP4, MP3, or WAV) to the designated S3 input bucket.
2. **Lambda Function Triggered**: Once a file is uploaded, a Lambda function automatically triggers an Amazon Transcribe job.
3. **Transcription Results**: The transcription results are stored in a separate S3 output bucket.

## 🛠️ Technology Stack
- **Amazon S3**: Secure storage for audio files and transcription results
- **AWS Lambda**: Event-driven computation for audio transcription trigger
- **Amazon Transcribe**: Speech-to-text transcription service
- **Amazon CloudWatch**: Logging for Lambda function activity
- **IAM Roles**: Secured access control for Lambda and S3

## 🧩 CloudFormation Resources
This stack provisions the following resources:
- **Input S3 Bucket**: Stores uploaded audio files to be transcribed
- **Output S3 Bucket**: Stores the transcription results
- **Logging S3 Bucket**: Stores S3 access logs
- **AWS Lambda**: Processes file uploads and triggers transcription jobs
- **IAM Role**: Provides necessary permissions to the Lambda function
- **CloudWatch Log Group**: Logs Lambda function execution

## 📦 Installation & Setup
Follow these steps to deploy the stack using AWS CloudFormation:

### Prerequisites
1. **AWS CLI** installed and configured on your machine.
2. **AWS Account** with sufficient permissions to deploy resources.

### Deploy the Stack
1. **Clone this repository** to your local machine:
   ```bash
   git clone https://github.com/yourusername/audio-transcription-automation.git
   cd audio-transcription-automation
   ```

2. **Deploy the CloudFormation stack** using the `deploy-transcription.sh` file or the AWS CLI:
   ```bash
   aws cloudformation deploy \
     --template-file transcribe.yaml \
     --stack-name audio-transcription-stack \
     --capabilities CAPABILITY_NAMED_IAM
   ```

3. **Monitor** the progress of the deployment in the AWS Console under **CloudFormation**.

4. Once the stack is successfully created, **upload audio files** to the designated input bucket to start the transcription process. 🎤

## 📂 Project Structure

```bash
.
├── cfn/transcribe.yaml          # CloudFormation Template
├── README.md              # Project Documentation

```

## 📊 Monitoring & Logging
- **CloudWatch Logs**: View the Lambda function execution logs in the AWS CloudWatch console.
- **S3 Access Logs**: Check access logs for the input and output S3 buckets in the logging bucket.

## 🤝 Contributing
We welcome contributions! Feel free to open a PR if you'd like to enhance this project.

### How to Contribute
1. Fork the repo 🍴
2. Create a new branch for your feature:
   ```bash
   git checkout -b feature/awesome-feature
   ```
3. Commit your changes 💻
4. Push your branch and submit a PR 🛠️

## 🌍 License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## 🏆 Acknowledgements
- Huge thanks to the **AWS** team for their powerful services! 💪
- Special shoutout to **OpenAI** for inspiring innovation with AI-based projects. 🙌

## 📬 Contact
Have any questions? Feel free to reach out via [GitHub Issues](https://github.com/yourusername/audio-transcription-automation/issues).

---

✨ **Happy Transcribing!** ✨

---

By adding this to your GitHub project, you'll give it a polished and engaging appearance that’s both informative and visually appealing! Let me know if you want to tweak anything further! 😊