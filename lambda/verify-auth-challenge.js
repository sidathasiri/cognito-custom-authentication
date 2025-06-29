exports.handler = async (event) => {
  const expectedAnswer = event.request.privateChallengeParameters.answer;
  const userAnswer = event.request.challengeAnswer;

  event.response.answerCorrect = userAnswer === expectedAnswer;

  return event;
};
