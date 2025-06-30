const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const sns = new SNSClient();

exports.handler = async (event) => {
  const phoneNumber = event.request.userAttributes.phone_number;

  console.log("Phone number:", phoneNumber);
  
  try {

    if (event.request.session.length === 0) {
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      
      await sns.send(new PublishCommand({
        Message: `Your verification code is: ${otp}`,
        PhoneNumber: phoneNumber,
      }));

      console.log('OTP sent successfully');
      

      event.response.publicChallengeParameters = {
        message: 'OTP sent via SMS',
      };

      event.response.privateChallengeParameters = {
        answer: otp,
      };

      event.response.challengeMetadata = 'SMS_OTP_CHALLENGE';
    }
    return event;
  } catch(e) {
    console.log('error:', e);
  }
};
